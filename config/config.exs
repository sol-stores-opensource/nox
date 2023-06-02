# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

# avoids Iex.pry() hanging liveviews in iex -S mix phx.server
config :elixir, :dbg_callback, {Macro, :dbg, []}

config :nox,
  env: config_env()

config :nox,
  ecto_repos: [Nox.Repo]

config :nox, Nox.Repo,
  types: Nox.PostgresTypes,
  migration_primary_key: [
    name: :id,
    type: :binary_id,
    default: {:fragment, "gen_random_uuid()"}
  ],
  migration_timestamps: [type: :timestamptz]

# Configures the endpoint
config :nox, NoxWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [view: NoxWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Nox.PubSub,
  live_view: [signing_salt: "SdcMaScV"]

config :tailwind,
  version: "3.0.7",
  default: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/tw.css
      --output=../priv/static/assets/tw.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :nox, Nox.Mailer, adapter: Swoosh.Adapters.Local

# Swoosh API client is needed for adapters other than SMTP.
config :swoosh, :api_client, false

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.14.0",
  default: [
    args:
      ~w(js/app.ts --bundle --loader:.png=file --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Oban

# ┌───────────── minute (0 - 59)
# │ ┌───────────── hour (0 - 23)
# │ │ ┌───────────── day of the month (1 - 31)
# │ │ │ ┌───────────── month (1 - 12)
# │ │ │ │ ┌───────────── day of the week (0 - 6) (Sunday to Saturday;
# │ │ │ │ │                                   7 is also Sunday on some systems)
# │ │ │ │ │
# │ │ │ │ │
# * * * * * <command to execute>
config :nox, Oban,
  engine: Oban.Pro.Queue.SmartEngine,
  repo: Nox.Repo,
  plugins: [
    Oban.Plugins.Gossip,
    Oban.Web.Plugins.Stats,
    {
      Oban.Pro.Plugins.DynamicCron,
      timezone: "America/Los_Angeles", crontab: []
    },
    {
      Oban.Pro.Plugins.DynamicPruner,
      queue_overrides: [],
      state_overrides: [
        cancelled: {:max_age, {1, :hour}},
        completed: {:max_age, {1, :day}},
        discarded: {:max_age, {1, :month}}
      ]
    },
    {Oban.Pro.Plugins.DynamicLifeline, rescue_interval: :timer.minutes(10)},
    Oban.Pro.Plugins.Reprioritizer
  ],
  queues: [
    default: 10,
    collect: [global_limit: 1],
    dummy_serial: [global_limit: 1]
  ]

config :nox, Nox.Vault, ciphers: []

config :petal_components, :error_translator_function, {NoxWeb.ErrorHelpers, :translate_error}

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
