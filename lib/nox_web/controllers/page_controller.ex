defmodule NoxWeb.PageController do
  use NoxWeb, :controller

  def index(conn, _params) do
    user = Map.get(conn.assigns, :current_user)

    render(conn, "index.html", user: user)
  end
end
