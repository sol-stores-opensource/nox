defmodule NoxWeb.LoginController do
  use NoxWeb, :controller

  def index(conn, _params) do
    user = Map.get(conn.assigns, :current_user)

    if user do
      conn
      |> redirect(to: "/")
    else
      oauth_google_url = ElixirAuthGoogle.generate_oauth_url(conn)

      conn
      |> redirect(external: oauth_google_url)
    end
  end

  def logout(conn, _params) do
    conn
    |> clear_session()
    |> put_flash(:info, "Logged out!")
    |> redirect(to: "/")
  end
end
