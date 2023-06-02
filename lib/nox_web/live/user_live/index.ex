defmodule NoxWeb.UserLive.Index do
  use NoxWeb, :live_view

  alias Nox.Users
  alias Nox.Repo.User

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :users, list_users())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit User")
    |> assign(:user, Users.get_user!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New User")
    |> assign(:user, %User{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Users")
    |> assign(:user, nil)
  end

  defp list_users do
    Users.list_users()
  end

  @impl true
  def handle_event("close_modal", opts, socket) do
    {:noreply, push_patch(socket, to: close_modal_redirect_to(opts, socket))}
  end

  defp close_modal_redirect_to(_opts, _socket) do
    ~p"/users"
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-row gap-x-5 mb-5">
      <.h2 class="grow">Listing Users</.h2>
    </div>

    <%= if @live_action in [:edit] do %>
      <.modal title={@page_title}>
        <.live_component
          module={NoxWeb.UserLive.FormComponent}
          id={@user.id}
          action={@live_action}
          user={@user}
          return_to={~p"/users"}
        />
      </.modal>
    <% end %>

    <.table>
      <thead>
        <.tr>
          <.th>ID</.th>
          <.th>Name</.th>
          <.th>Email</.th>
          <.th>Roles</.th>

          <.th></.th>
        </.tr>
      </thead>
      <tbody id="users">
        <%= for user <- @users do %>
          <.tr id={"user-#{user.id}"}>
            <.td>
              <%= user.id %>
            </.td>
            <.td>
              <%= user.name %>
            </.td>
            <.td>
              <%= user.email %>
            </.td>
            <.td>
              <%= if user.roles do %>
                <%= for {k, _v} <- user.roles do %>
                  <%= k %>
                <% end %>
              <% end %>
            </.td>

            <.td class="whitespace-nowrap w-px">
              <.a link_type="live_patch" to={~p"/users/#{user}/edit"}>
                <HeroiconsV1.Outline.pencil_alt class="h-6 w-6" />
              </.a>
            </.td>
          </.tr>
        <% end %>
      </tbody>
    </.table>
    """
  end
end
