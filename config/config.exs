import Config

config :crawly,
  closespider_timeout: 1,
  concurrent_requests_per_domain: 1,
  closespider_itemcount: 10,
  middlewares: [
    Crawly.Middlewares.DomainFilter,
    Crawly.Middlewares.RobotsTxt,
    Crawly.Middlewares.UniqueRequest,
    {Crawly.Middlewares.UserAgent,
     user_agents: [
       "[https://simontirant.dev | simon.tirant@gmail.com] Hi, I am looking for an Elixir developper position so I made this web crawler."
     ]}
  ],
  pipelines: [
    # {Crawly.Pipelines.Validate, fields: [:title, :experience, :url]},
    # {Crawly.Pipelines.DuplicatesFilter, item_id: :title},
    {Crawly.Pipelines.Validate, fields: [:hash, :html]},
    {Crawly.Pipelines.DuplicatesFilter, item_id: :hash},
    Crawly.Pipelines.JSONEncoder,
    {Crawly.Pipelines.WriteToFile,
     extension: "jsonl", folder: "./priv/tmp", include_timestamp: false}
  ]

config :swoosh, :api_client, Swoosh.ApiClient.Finch

config :scrapex, Scrapex.Mailer,
  adapter: Swoosh.Adapters.Sendgrid,
  api_key: System.get_env("SENDGRID_KEY")

config :scrapex,
  sender_mail: System.get_env("SENDER_MAIL"),
  recipient: %{
    mail: System.get_env("RECIPIENT_MAIL"),
    name: System.get_env("RECIPIENT_NAME")
  }
