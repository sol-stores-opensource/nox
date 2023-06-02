import Config

required_env_val = fn key ->
  System.get_env(key) || raise "environment variable #{key} is missing."
end

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# Start the phoenix server if environment is set and running in a release
if System.get_env("PHX_SERVER") && System.get_env("RELEASE_NAME") do
  config :nox, NoxWeb.Endpoint, server: true
end

if config_env() == :dev do
  config :nox,
    goth_source:
      {:service_account, File.read!("config/dev-service-account.secret.json") |> Jason.decode!(),
       scopes: ["https://www.googleapis.com/auth/cloud-platform"]}
end

if config_env() == :prod do
  config :nox,
    nox_warn_deploy_env: System.get_env("nox_warn_deploy_env")

  config :nox,
    tuts_url_base: required_env_val.("TUTS_URL_BASE")

  config :nox,
    google_auth_domain: required_env_val.("GOOGLE_AUTH_DOMAIN"),
    kiosk_url: required_env_val.("KIOSK_URL")

  config :mux,
    access_token_id: required_env_val.("MUX_ACCESS_TOKEN_ID"),
    access_token_secret: required_env_val.("MUX_ACCESS_TOKEN_SECRET"),
    webhook_secret: required_env_val.("MUX_WEBHOOK_SECRET")

  config :nox,
    decaf_shop_id: required_env_val.("DECAF_SHOP_ID"),
    decaf_airdrop_api_url: required_env_val.("DECAF_AIRDROP_API_URL"),
    decaf_le_config_api_key: required_env_val.("decaf_le_config_api_key"),
    decaf_le_config_api_url: required_env_val.("decaf_le_config_api_url"),
    decaf_le_solana_qr_url: required_env_val.("decaf_le_solana_qr_url")

  config :nox,
    nox_dataset: required_env_val.("NOX_DATASET"),
    collect_table: required_env_val.("COLLECT_TABLE"),
    goth_source:
      {:service_account, File.read!("/secrets/google-sa.json") |> Jason.decode!(),
       scopes: ["https://www.googleapis.com/auth/cloud-platform"]},
    uploads_bucket: required_env_val.("UPLOADS_BUCKET")

  config :nox,
    cloak_vault_key: required_env_val.("cloak_vault_key")

  config :swoosh, :api_client, Swoosh.ApiClient.Hackney

  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  maybe_ipv6 = if System.get_env("ECTO_IPV6"), do: [:inet6], else: []

  config :nox, Nox.Repo,
    # ssl: true,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    socket_options: maybe_ipv6

  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "example.com"
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :nox, NoxWeb.Endpoint,
    url: [scheme: "https", host: host, port: 443],
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      # See the documentation on https://hexdocs.pm/plug_cowboy/Plug.Cowboy.html
      # for details about using IPv6 vs IPv4 and loopback vs public addresses.
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    secret_key_base: secret_key_base,
    check_origin: false

  config :nox,
    env: config_env(),
    app_revision: System.get_env("APP_REVISION")

  config :libcluster,
    topologies: [
      k8s: [
        strategy: Cluster.Strategy.Kubernetes,
        config: [
          kubernetes_node_basename: System.get_env("RELEASE_NAME"),
          kubernetes_selector: "app=#{required_env_val.("MY_K8S_APP")}",
          kubernetes_namespace: required_env_val.("MY_K8S_NAMESPACE"),
          polling_interval: 5_000
        ]
      ]
    ]

  config :elixir_auth_google,
    client_id: required_env_val.("AUTH_GOOGLE_CLIENT_ID"),
    client_secret: required_env_val.("AUTH_GOOGLE_CLIENT_SECRET")

  # ## Using releases
  #
  # If you are doing OTP releases, you need to instruct Phoenix
  # to start each relevant endpoint:
  #
  #     config :nox, NoxWeb.Endpoint, server: true
  #
  # Then you can assemble a release by calling `mix release`.
  # See `mix help release` for more information.

  # ## Configuring the mailer
  #
  # In production you need to configure the mailer to use a different adapter.
  # Also, you may need to configure the Swoosh API client of your choice if you
  # are not using SMTP. Here is an example of the configuration:
  #
  #     config :nox, Nox.Mailer,
  #       adapter: Swoosh.Adapters.Mailgun,
  #       api_key: System.get_env("MAILGUN_API_KEY"),
  #       domain: System.get_env("MAILGUN_DOMAIN")
  #
  # For this example you need include a HTTP client required by Swoosh API client.
  # Swoosh supports Hackney and Finch out of the box:
  #
  #     config :swoosh, :api_client, Swoosh.ApiClient.Hackney
  #
  # See https://hexdocs.pm/swoosh/Swoosh.html#module-installation for details.
end
