defmodule NoxWeb.Auth.RolePlug do
  require Logger
  alias Nox.Repo
  alias Nox.Users

  @behaviour Plug

  def init(roles: roles) when is_list(roles), do: roles

  def call(%{assigns: %{current_user: %Repo.User{} = current_user}} = conn, roles) do
    found =
      roles
      |> Enum.find(fn role -> Users.has_role?(current_user, role) end)

    if found do
      conn
    else
      no_permission(conn)
    end
  end

  def call(conn, _) do
    conn
    |> not_authorized()
  end

  defp not_authorized(conn) do
    conn
    |> Phoenix.Controller.put_flash("error", "Not authorized")
    |> Phoenix.Controller.redirect(external: "/")
    |> Plug.Conn.halt()
  end

  defp no_permission(conn) do
    conn
    |> Phoenix.Controller.put_flash("error", "No permission")
    |> Phoenix.Controller.redirect(external: "/")
    |> Plug.Conn.halt()
  end
end
