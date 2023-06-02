defmodule NoxWeb.Auth.RoleHook do
  import Phoenix.LiveView

  alias Nox.Users

  def on_mount([roles: roles], _params, _session, socket) when is_list(roles) do
    found =
      roles
      |> Enum.find(fn role -> Users.has_role?(socket.assigns.current_user, role) end)

    if found do
      {:cont, socket}
    else
      socket =
        socket
        |> redirect(to: "/")

      {:halt, socket}
    end
  end
end
