import Config

domain_name = System.get_env("DOMAIN_NAME")
smtp = "smtp." <> "#{domain_name}"

sender_name = System.get_env("SENDER_NAME")

sender_mail = "#{System.get_env("SENDER_NAME")}@#{System.get_env("DOMAIN_NAME")}"

sender_pwd = System.get_env("SENDER_PWD")
recipient_name = System.get_env("RECIPIENT_NAME")
recipient_mail = System.get_env("RECIPIENT_MAIL")

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
  relay: smtp,
  username: sender_mail,
  password: sender_pwd,
  ssl: false,
  tls: :always,
  auth: :always,
  port: 587,
  dkim: [
    s: sender_name,
    d: domain_name,
    private_key: {:pem_plain, File.read!("priv/keys/private-key.pem")}
  ],
  retries: 2,
  no_mx_lookups: false

config :scrapex,
  sender_mail: sender_mail,
  recipient: %{
    mail: recipient_mail,
    name: recipient_name
  }
