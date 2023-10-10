defmodule Scrapex.JobSpiders.CuriosumSpider do
  @moduledoc """
  Spider made to crawl Curiosum job offers at https://curiosum.com/careers .
  """

  use Crawly.Spider

  @impl Crawly.Spider
  def base_url(), do: "https://curiosum.com/"

  @impl Crawly.Spider
  def init(), do: [start_urls: ["https://curiosum.com/careers"]]

  @impl Crawly.Spider
  def parse_item(response) do
    {:ok, page_body} = Floki.parse_document(response.body)

    jobs =
      page_body
      |> Floki.find("main.career div.container div.career-list__container")
      |> Floki.raw_html()

    %Crawly.ParsedItem{:items => [%{jobs: jobs}], :requests => []}
  end
end
