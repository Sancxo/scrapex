defmodule Scrapex.SpidersNest do
  @moduledoc """
  GenServer to handle spiders launch and to send emails.
  """
  alias Scrapex.Mailer

  use GenServer
  require Logger

  @timer 24 * 60 * 60 * 1000
  @spiders [
    Scrapex.JobSpiders.FlySpider,
    Scrapex.JobSpiders.DockyardSpider,
    Scrapex.JobSpiders.CuriosumSpider
  ]

  def start_link(_opts), do: GenServer.start_link(__MODULE__, %{})

  @impl true
  def init(state) do
    daily_crawl(state)

    {:ok, state}
  end

  @impl true
  def handle_info({:put_spider, spider, crawl_id}, state),
    do: {:noreply, state |> Map.put(spider, crawl_id)}

  def handle_info(:crawl, state) do
    daily_crawl(state)

    {:noreply, state}
  end

  defp daily_crawl(state) do
    for spider <- @spiders do
      current_crawl_id = UUID.uuid1()

      Crawly.Engine.start_spider(spider, crawl_id: current_crawl_id)

      # dirty !
      # how to get a message from Crawly.Pipelines.WriteToFile.run()
      # monitor it ? (returns the item and the state in a tuple {item, state})
      Process.sleep(10000)

      spider = spider |> Atom.to_string() |> String.trim_leading("Elixir.")

      state
      |> Map.has_key?(spider)
      |> case do
        true ->
          previous_crawl_id = state[spider]

          # we open last and current record files in order to get the recorded hashes
          with previous_record <- File.read!("./priv/tmp/#{spider}_#{previous_crawl_id}.jsonl"),
               current_record <- File.read!("./priv/tmp/#{spider}_#{current_crawl_id}.jsonl") do
            [previous_record, current_record] =
              [previous_record, current_record] |> Enum.map(&Poison.decode!(&1))

            if previous_record["hash"] == current_record["hash"] do
              # If hashes match, we remove this crawl file and we do nothing
              Logger.info("Hash #{current_record["hash"]}, already exists, we delete this crawl.")

              File.rm!("./priv/tmp/#{spider}_#{current_crawl_id}.jsonl")
            else
              (previous_record["hash"] == current_record["hash"])
              |> IO.inspect(label: "Les deux hashes NE matchent PAS !!!")

              # si les hash ne matchent pas, on écrit le nouveau crawl_id dans le state et on envoie un mail
              Process.send(self(), {:put_spider, spider, current_crawl_id}, [
                :noconnect,
                :nosuspend
              ])

              spider |> Mailer.build_mail(current_record["html"], :html) |> Mailer.deliver()
            end
          end

        false ->
          # les hash n'existent pas, on écrit le crawl id actuel dans le state et on envoie un mail
          # pb: si le Genserver a reboot, alors le state sera vide à nouveau
          # et on arrivera ici alors que le storage contiendra un record précédent
          # Solution, si le state est vide, checker au cas où le contenu de :dets pour get le dernier crawl_id pour cette spider (:dets.select())
          Logger.info("No crawl_id in state for #{spider |> inspect()}")
          Process.send(self(), {:put_spider, spider, current_crawl_id}, [:noconnect, :nosuspend])

          %{"html" => html} =
            File.read!("./priv/tmp/#{spider}_#{current_crawl_id}.jsonl") |> Poison.decode!()

          spider
          |> Mailer.build_mail(html, :html)
          |> Mailer.deliver()
      end

      Process.send_after(self(), :crawl, @timer)
    end
  end
end
