defmodule Scrapex.JobSpiders.FlySpider do
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
      |> Floki.find("section.container div.grid article")
      |> Enum.map(fn article ->
        job_experience =
          article
          |> Floki.find("dl:nth-of-type(2) dd:not([aria-hidden])")
          |> Floki.text()
          |> String.split("\n")
          |> Enum.map(&String.trim/1)
          |> Enum.filter(fn job_xp -> job_xp != "" end)

        unless List.first(job_experience) == "No positions available at this time" do
          %{
            title:
              article
              |> Floki.find("dl:first-child > dd:not(.hidden)")
              |> Floki.text()
              |> String.split("\n", trim: true)
              |> List.first()
              |> String.trim(),
            experience: job_experience,
            link: article |> Floki.find("a") |> Floki.attribute("href") |> List.first()
          }
        end
      end)
      |> Enum.filter(&(&1 != nil))

    %Crawly.ParsedItem{:items => [%{jobs: jobs}], :requests => []}
  end
end
