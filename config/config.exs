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
       "[https://simontirant.dev | simon.tirant@gmail.com] Hi, I am looking for an Elixir developper position so I made this job scrapping GenServer."
     ]}
  ],
  pipelines: [
    {Crawly.Pipelines.Validate, fields: [:hash, :html]},
    Crawly.Pipelines.JSONEncoder,
    {Crawly.Pipelines.WriteToFile,
     extension: "jsonl", folder: "./priv/tmp", include_timestamp: false}
  ]

config :swoosh, :api_client, false

config :scrapex, Scrapex.Mailer,
  adapter: Swoosh.Adapters.SMTP,
  relay: "smtp." <> "#{System.get_env("DOMAIN_NAME")}",
  username: System.get_env("SENDER_MAIL"),
  password: System.get_env("SENDER_PWD"),
  ssl: false,
  tls: :always,
  auth: :always,
  port: 587,
  dkim: [
    s: System.get_env("SENDER_NAME"),
    d: System.get_env("DOMAIN_NAME"),
    private_key: {:pem_plain, File.read!("priv/keys/private-key.pem")}
  ],
  retries: 2,
  no_mx_lookups: false

config :scrapex,
  sender_mail: System.get_env("SENDER_MAIL"),
  recipient: %{
    mail: System.get_env("RECIPIENT_MAIL"),
    name: System.get_env("RECIPIENT_NAME")
  }
