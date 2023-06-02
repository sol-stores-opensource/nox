defmodule NoxWeb.LearnEarnSocket do
  require Logger
  use Phoenix.Socket

  ## Channels
  channel "learn_earn:*", NoxWeb.LearnEarnChannel
  channel "learn_earn_lobby", NoxWeb.LearnEarnLobbyChannel

  # Socket params are passed from the client and can
  # be used to verify and authenticate a user. After
  # verification, you can put default assigns into
  # the socket that will be set for all channels, ie
  #
  #     {:ok, assign(socket, :user_id, verified_user_id)}
  #
  # To deny connection, return `:error`.
  #
  # See `Phoenix.Token` documentation for examples in
  # performing token verification on connect.
  @impl true
  def connect(_params, socket, %{x_headers: x_headers, uri: uri}) do
    socket =
      socket
      |> assign(:loki_authorized?, loki_authorized?(x_headers, uri))

    {:ok, socket}
  end

  # Socket id's are topics that allow you to identify all sockets for a given user:
  #
  #     def id(socket), do: "user_socket:#{socket.assigns.user_id}"
  #
  # Would allow you to broadcast a "disconnect" event and terminate
  # all active sockets and channels for a given user:
  #
  #     ThorWeb.Endpoint.broadcast("user_socket:#{user.id}", "disconnect", %{})
  #
  # Returning `nil` makes this socket anonymous.
  @impl true
  def id(_), do: nil

  def get_loki_auth_config() do
    Nox.Repo.BinaryKv.get("loki_auth_config") || %{}
  end

  def put_loki_auth_enabled(enabled) do
    config =
      get_loki_auth_config()
      |> Map.put(:enabled, enabled)

    Nox.Repo.BinaryKv.put("loki_auth_config", config)
  end

  def put_loki_secret(secret) do
    config =
      get_loki_auth_config()
      |> Map.put(:secret, secret)

    Nox.Repo.BinaryKv.put("loki_auth_config", config)
  end

  def put_loki_auth_allowed_ips(ips) when is_list(ips) do
    config =
      get_loki_auth_config()
      |> Map.put(:allowed_ips, ips)

    Nox.Repo.BinaryKv.put("loki_auth_config", config)
  end

  def loki_authorized?(x_headers, %URI{} = uri) do
    config = get_loki_auth_config()

    if Map.get(config, :enabled) == true do
      is_allowed_uri?(uri, Map.get(config, :secret)) ||
        is_allowed_ip?(x_headers, Map.get(config, :allowed_ips) || [])
    else
      true
    end
  end

  def is_allowed_uri?(%URI{} = uri, secret)
      when is_binary(secret) and secret != nil do
    with q_str when is_binary(q_str) <- Map.get(uri, :query),
         %{"secret" => ^secret} <- URI.decode_query(q_str) do
      true
    else
      _ ->
        false
    end
  end

  def is_allowed_uri?(_uri, _secret), do: false

  def is_allowed_ip?(x_headers, allowed_ips) do
    x_headers =
      x_headers
      |> Map.new()

    ip =
      case Map.get(x_headers, "x-forwarded-for") do
        str when is_binary(str) ->
          str
          |> String.split(",")
          |> Enum.map(fn x -> String.trim(x) end)
          |> Enum.find(fn ip ->
            res =
              ip
              |> String.to_charlist()
              |> :inet_parse.ipv4strict_address()

            case res do
              {:ok, _} -> true
              _ -> false
            end
          end)

        _ ->
          nil
      end

    ip in allowed_ips
  end
end
