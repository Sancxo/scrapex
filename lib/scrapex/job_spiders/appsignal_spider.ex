defmodule Scrapex.JobSpiders.AppsignalSpider do
  @moduledoc "Spider made to crawl Appsignal.com job offers at https://www.appsignal.com/jobs."
  use Crawly.Spider

  @impl Crawly.Spider
  def base_url(), do: "https://www.appsignal.com/"

  @impl Crawly.Spider
  def init(), do: [start_urls: ["https://www.appsignal.com/jobs"]]

  @impl Crawly.Spider
  def parse_item(response) do
    {:ok, page_body} = Floki.parse_document(response.body)

    jobs =
      page_body
      |> Floki.find("div.c-container div ul li:not(.items-baseline)")
      |> Enum.map(fn job ->
        job
        |> Floki.traverse_and_update(fn
          {"a", _, [_, {"span", _attrs, ["Closed"]}]} ->
            nil

          {"a", _, [{"span", _, _}, {"span", _, _}]} = job_block ->
            job_block

          _ ->
            nil
        end)
        |> case do
          nil ->
            nil

          job_block ->
            job_block |> Floki.raw_html()
        end
      end)

    header = page_body |> Floki.find("header.c-container") |> Floki.raw_html()

    data = [header | jobs] |> Enum.join()

    digest = :crypto.hash(:sha256, data) |> Base.encode16() |> String.downcase()

    %Crawly.ParsedItem{:items => [%{hash: digest, html: data}], :requests => []}
  end
end
