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

    digest = :crypto.hash(:sha256, jobs) |> Base.encode16() |> String.downcase()

    %Crawly.ParsedItem{:items => [%{hash: digest, html: jobs}], :requests => []}
  end
end
