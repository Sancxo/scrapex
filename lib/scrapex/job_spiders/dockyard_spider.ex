defmodule Scrapex.JobSpiders.DockyardSpider do
  @moduledoc """
  Spider made to crawl Dockyard job offers at https://dockyard.com/careers .
  """

  use Crawly.Spider

  @impl Crawly.Spider
  def base_url(), do: "https://dockyard.com/"

  @impl Crawly.Spider
  def init(), do: [start_urls: ["https://dockyard.com/careers"]]

  @impl Crawly.Spider
  def parse_item(response) do
    {:ok, page_body} = Floki.parse_document(response.body)

    jobs =
      page_body
      |> Floki.find("main section[aria-labelledby='open-positions']")
      |> Floki.raw_html()

    digest = :crypto.hash(:sha256, jobs) |> Base.encode16() |> String.downcase()

    %Crawly.ParsedItem{:items => [%{hash: digest, html: jobs}], :requests => []}
  end
end
