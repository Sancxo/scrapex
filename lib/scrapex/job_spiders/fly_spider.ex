defmodule Scrapex.JobSpiders.FlySpider do
  @moduledoc """
  Spider made to crawl Fly.io job offers at https://fly.io/jobs/ .
  """
  use Crawly.Spider

  @impl Crawly.Spider
  def base_url(), do: "https://fly.io/"

  @impl Crawly.Spider
  def init(), do: [start_urls: ["https://fly.io/jobs/"]]

  @impl Crawly.Spider
  def parse_item(response) do
    {:ok, page_body} = Floki.parse_document(response.body)

    jobs =
      page_body
      |> Floki.find("main section.container div.grid article")
      |> Enum.map(fn article ->
        # Fly.io doesn't remove old job offers, so we have to check if the job offer has experience requirements or "No positions available at this time" in order to return only open positions.
        job_experience =
          article
          |> Floki.find("dl:nth-of-type(2) dd:not([aria-hidden])")
          |> Floki.text()
          |> String.split("\n")
          |> Enum.map(&String.trim/1)
          |> Enum.filter(fn job_xp -> job_xp != "" end)

        unless List.first(job_experience) == "No positions available at this time",
          do: Floki.raw_html(article)

        # Old map used as value returned, now the function returns raw html but in case we revert to map type this could be useful
        # unless List.first(job_experience) == "No positions available at this time" do
        # %{
        #   title:
        #     article
        #     |> Floki.find("dl:first-child > dd:not(.hidden)")
        #     |> Floki.text()
        #     |> String.split("\n", trim: true)
        #     |> List.first()
        #     |> String.trim(),
        #   experience: job_experience,
        #   url: article |> Floki.find("a") |> Floki.attribute("href") |> List.first()
        # }
        # end
      end)
      |> Enum.filter(&(&1 != nil))

    digest = :crypto.hash(:sha256, jobs) |> Base.encode16() |> String.downcase()

    # open last record file
    # File.read("/tmp/#{__MODULE__}.jsonl")
    # |> IO.inspect(label: "File ?")
    # |> case do
    #   {:error, :enoent} ->
    %Crawly.ParsedItem{:items => [%{hash: digest, html: jobs}], :requests => []}

    #   {:ok, json} ->
    #     json |> IO.inspect(label: "We found a file!")
    # end
  end
end
