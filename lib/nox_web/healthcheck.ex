defmodule NoxWeb.Healthcheck do
  require Logger
  import Plug.Conn

  @behaviour Plug

  @path_startup "/healthz/startup"
  @path_liveness "/healthz/liveness"
  @path_readiness "/healthz/readiness"
  @path_headers "/healthz/headers"

  # Plug Callbacks

  @impl true
  def init(opts), do: opts

  @impl true
  def call(%Plug.Conn{} = conn, _opts) do
    case conn.request_path do
      @path_startup ->
        health_response(conn, has_started?())

      @path_liveness ->
        health_response(conn, is_alive?())

      @path_readiness ->
        health_response(conn, is_ready?())

      @path_headers ->
        Logger.info("#{__MODULE__} conn=#{inspect(conn, limit: :infinity, stucts: false)}")
        health_response(conn, true)

      _other ->
        conn
    end
  end

  # Respond according to health checks

  defp health_response(conn, true) do
    conn
    |> send_resp(200, "OK")
    |> halt()
  end

  defp health_response(conn, false) do
    conn
    |> send_resp(503, "SERVICE UNAVAILABLE")
    |> halt()
  end

  @doc """
  Check if required services are loaded and startup
  tasks completed
  """
  def has_started? do
    is_alive?() && goth_ok?()
  end

  def goth_ok?() do
    case Goth.fetch(Nox.Goth) do
      {:ok, _} -> true
      _ -> false
    end
  end

  @doc """
  Check if app is alive and working, by making a simple
  request to the DB
  """
  def is_alive? do
    Ecto.Adapters.SQL.query!(Nox.Repo, "SELECT 1") != nil
  rescue
    _e -> false
  end

  @doc """
  Check if app should be serving public traffic
  """
  def is_ready? do
    Application.get_env(:nox, :maintenance_mode) != :enabled
  end

  def https_excluded_host?(host) do
    host != NoxWeb.Endpoint.host()
  end
end
