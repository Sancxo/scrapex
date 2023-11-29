defmodule Scrapex.JobSpiders.FeltSpider do
  @moduledoc "Spider made to crawl Felt.com job offers at https://felt.com/careers."
  use Crawly.Spider

  @impl Crawly.Spider
  def base_url(), do: "https://felt.com/"

  @impl Crawly.Spider
  def init(), do: [start_urls: ["https://felt.com/careers"]]

  @impl Crawly.Spider
  def parse_item(response) do
    {:ok, page_body} = Floki.parse_document(response.body)

    jobs =
      page_body
      |> Floki.find("div.role-row div.left-pane-careers div.div-block-3 div.indiv-three-up")
      |> Enum.map(fn job ->
        job
        |> Floki.traverse_and_update(fn
          {"div", [{"class", "h4"}], text} ->
            # we add some style (weight bold and margin) to job titles
            {"div", [{"class", "h4"}, {"style", "font-weight: bold; margin-top: 3rem;"}], text}

          {"div", [{"class", "body-text-div bullet-box"}],
           [
             {tag, attrs, [first_child_text | _]},
             {_, _, [{"span", _, [second_child_text | _]} | _]}
           ]} ->
            # Used to fix the bullet list (when the text is inside a span)
            {"div", [{"class", "body-text-div bullet-box"}],
             [
               {tag, attrs, [first_child_text <> second_child_text]}
             ]}

          {"div", [{"class", "body-text-div bullet-box"}],
           [{tag, attrs, [first_child_text | _]}, {_, _, [second_child_text | _]}]} ->
            # Used to fix the bullet list (general case)
            {"div", [{"class", "body-text-div bullet-box"}],
             [
               {tag, attrs, [first_child_text <> second_child_text]}
             ]}

          html_tag ->
            html_tag
        end)
        |> Floki.raw_html()
      end)

    # we get the job section title and description in order to add it at the begining of the email
    title =
      page_body
      |> Floki.find("div.section-title-container")
      |> tl()
      |> Floki.raw_html()

    data = [title | jobs] |> Enum.join()

    digest = :crypto.hash(:sha256, data) |> Base.encode16() |> String.downcase()

    %Crawly.ParsedItem{:items => [%{hash: digest, html: data}], :requests => []}
  end
end
