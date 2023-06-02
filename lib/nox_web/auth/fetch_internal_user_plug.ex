defmodule NoxWeb.Auth.FetchInternalUserPlug do
  require Logger
  import Plug.Conn

  @behaviour Plug

  def init(opts), do: opts

  def call(conn, _) do
    with %{"current_user" => user_id} <- get_session(conn) do
      user = Nox.Users.get_by_id(user_id)

      conn
      |> assign(:current_user, user)
    else
      _ ->
        conn
    end
  end
end
