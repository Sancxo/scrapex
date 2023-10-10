defmodule Scrapex.SpidersNest do
  @moduledoc """
  GenServer to handle spiders launch and to send emails.
  """

  use GenServer

  @timer 24 * 60 * 60 * 1000
  @spiders [
    Scrapex.JobSpiders.FlySpider,
    Scrapex.JobSpiders.DockyardSpider,
    Scrapex.JobSpiders.CuriosumSpider
  ]

  def start_link(_opts), do: GenServer.start_link(__MODULE__, %{})

  @impl true
  def init(state) do
    daily_crawl()

    {:ok, state}
  end

  @impl true
  def handle_info(:crawl, state) do
    daily_crawl()

    {:noreply, state}
  end

  defp daily_crawl() do
    for spider <- @spiders do
      Crawly.Engine.start_spider(spider)
    end

    Process.send_after(self(), :crawl, @timer)
  end
end
