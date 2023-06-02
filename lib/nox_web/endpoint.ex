defmodule NoxWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :nox

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  @session_options [
    store: :cookie,
    key: "_nox_key",
    signing_salt: "qEcVxyZR"
  ]

  socket "/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]]

  socket "/learn_earn", NoxWeb.LearnEarnSocket,
    websocket: [connect_info: [:x_headers, :uri]],
    longpoll: false

  # healthcheck halts pipeline avoiding logging, etc
  plug NoxWeb.Healthcheck

  plug RemoteIp

  plug Corsica,
    origins: "*",
    allow_methods: :all,
    allow_headers: :all,
    allow_credentials: true,
    log: [rejected: :info, invalid: :warn, accepted: :debug]

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/",
    from: :nox,
    gzip: false,
    only: ~w(assets fonts images favicon.ico robots.txt)

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :nox
  end

  plug Phoenix.LiveDashboard.RequestLogger,
    param_key: "request_logger",
    cookie_key: "request_logger"

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    body_reader: {NoxWeb.BodyReader, :read_body, []},
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  plug NoxWeb.Router

  def node_name() do
    node() || ""
  end
end
