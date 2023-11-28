defmodule Scrapex.SpidersNest do
  @moduledoc "GenServer to handle daily spiders launch and to send emails when new job positions are open."
  alias Scrapex.{HashRegistry, Mailer}

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
  def init(state \\ []) do
    daily_crawl()

    {:ok, state}
  end

  @impl true
  def handle_info(:crawl, state) do
    daily_crawl()

    {:noreply, state}
  end

  defp daily_crawl() do
    # If the digest doesn't match the hash stored in the ets table
    # or if there no hash in the ets table, we upsert the entry
    # with the Spider as a key and the digest as a value;
    # then we send an email
    for spider <- @spiders do
      current_crawl_id = UUID.uuid1()

      Crawly.Engine.start_spider(spider, crawl_id: current_crawl_id)

      # dirty !
      # how to get a message from Crawly.Pipelines.WriteToFile.run()
      # monitor it ? (returns the item and the state in a tuple {item, state})
      Process.sleep(10000)

      spider = spider |> Atom.to_string() |> String.trim_leading("Elixir.")

      # we open current record files in order to get the recorded html data
      %{"hash" => new_hash, "html" => html} =
        "./priv/tmp/#{spider}_#{current_crawl_id}.jsonl" |> File.read!() |> Poison.decode!()

      unless HashRegistry.lookup(spider) == new_hash do
        spider |> HashRegistry.upsert(new_hash)
        spider |> Mailer.build_mail(html, :html) |> Mailer.deliver()
      end

      "./priv/tmp/#{spider}_#{current_crawl_id}.jsonl" |> File.rm!()

      Process.send_after(self(), :crawl, @timer)
    end
  end
end
