import Config

config :crawly,
  closespider_timeout: 1,
  concurrent_requests_per_domain: 1,
  closespider_itemcount: 10,
  middlewares: [
    Crawly.Middlewares.DomainFilter,
    Crawly.Middlewares.UniqueRequest,
    {Crawly.Middlewares.UserAgent,
     user_agents: [
       "[https://simontirant.dev | simon.tirant@gmail.com] Hi, I am looking for an Elixir developper position so I made this web crawler."
     ]}
  ],
  pipelines: [
    # {Crawly.Pipelines.Validate, fields: [:url, :title, :price]},
    # {Crawly.Pipelines.DuplicatesFilter, item_id: :title},
    Crawly.Pipelines.JSONEncoder,
    {Crawly.Pipelines.WriteToFile, extension: "jsonl", folder: "./tmp", include_timestamp: true}
  ]
