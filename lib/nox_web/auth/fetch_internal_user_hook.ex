defmodule NoxWeb.Auth.FetchInternalUserHook do
  import Phoenix.Component

  def on_mount(:default, _params, session, socket) do
    user = Nox.Users.get_by_id(Map.get(session, "current_user"))

    socket =
      socket
      |> assign(:current_user, user)

    {:cont, socket}
  end
end
