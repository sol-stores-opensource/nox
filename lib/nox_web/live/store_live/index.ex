defmodule NoxWeb.StoreLive.Index do
  use NoxWeb, :live_view

  alias Nox.Stores
  alias Nox.Repo.Store

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :stores, list_stores())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Store")
    |> assign(:store, Stores.get_store!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Store")
    |> assign(:store, %Store{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Stores")
    |> assign(:store, nil)
  end

  @impl true
  def handle_event("close_modal", _, socket) do
    {:noreply, push_patch(socket, to: ~p"/stores")}
  end

  defp list_stores do
    Stores.list_stores()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-row gap-x-5 mb-5">
      <.h2 class="grow">Stores</.h2>
      <.button link_type="live_patch" label="New Store" to={~p"/stores/new"} />
    </div>

    <%= if @live_action in [:new, :edit] do %>
      <.modal title={@page_title}>
        <.live_component
          module={NoxWeb.StoreLive.FormComponent}
          id={@store.id || :new}
          action={@live_action}
          store={@store}
          return_to={~p"/stores"}
        />
      </.modal>
    <% end %>

    <.table>
      <thead>
        <.tr>
          <.th>Name</.th>
          <.th>Slug</.th>
          <.th>Decaf</.th>
          <.th>Misc</.th>

          <.th></.th>
        </.tr>
      </thead>
      <tbody id="stores">
        <%= for store <- @stores do %>
          <.tr id={"store-#{store.id}"}>
            <.td>
              <%= store.name %>
            </.td>
            <.td>
              <%= store.slug %>
            </.td>
            <.td>
              <div><%= store.decaf_shop_id %></div>
              <div><%= store.decaf_airdrop_api_url %></div>
            </.td>
            <.td>
              <%= for misc <- store.misc do %>
                <div><%= misc.key %>: <%= misc.value %></div>
              <% end %>
            </.td>

            <.td class="whitespace-nowrap w-px">
              <.a link_type="live_patch" to={~p"/stores/#{store}/edit"}>
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
