defmodule NoxWeb.LePartnerLive.Index do
  use NoxWeb, :live_view

  alias Nox.LearnEarn
  alias Nox.Repo.LePartner

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :le_partners, list_le_partners())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Partner")
    |> assign(:le_partner, LearnEarn.get_le_partner!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Partner")
    |> assign(:le_partner, %LePartner{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Partners")
    |> assign(:le_partner, nil)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    le_partner = LearnEarn.get_le_partner!(id)
    {:ok, _} = LearnEarn.delete_le_partner(le_partner)

    {:noreply, assign(socket, :le_partners, list_le_partners())}
  end

  @impl true
  def handle_event("close_modal", _, socket) do
    {:noreply, push_patch(socket, to: ~p"/le_partners")}
  end

  defp list_le_partners do
    LearnEarn.list_le_partners()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-row gap-x-5 mb-5">
      <.h2 class="grow">Learn &amp; Earn Partners</.h2>
      <.button link_type="live_patch" label="New Partner" to={~p"/le_partners/new"} />
    </div>

    <%= if @live_action in [:new, :edit] do %>
      <.modal title={@page_title}>
        <.live_component
          module={NoxWeb.LePartnerLive.FormComponent}
          id={@le_partner.id || :new}
          action={@live_action}
          le_partner={@le_partner}
          return_to={~p"/le_partners"}
        />
      </.modal>
    <% end %>

    <.table>
      <thead>
        <.tr>
          <.th>Name</.th>

          <.th></.th>
          <.th></.th>
        </.tr>
      </thead>
      <tbody id="le_partners">
        <%= for le_partner <- @le_partners do %>
          <.tr id={"le_partner-#{le_partner.id}"}>
            <.td>
              <.a
                link_type="live_redirect"
                to={~p"/le_partners/#{le_partner}"}
                class="text-purple-500"
              >
                <%= le_partner.name %>
              </.a>
            </.td>

            <.td class="whitespace-nowrap w-px">
              <.a link_type="live_patch" to={~p"/le_partners/#{le_partner}/edit"}>
                <HeroiconsV1.Outline.pencil_alt class="h-6 w-6" />
              </.a>
            </.td>
            <.td class="whitespace-nowrap w-px">
              <.a to="#" phx-click="delete" phx-value-id={le_partner.id} data-confirm="Are you sure?">
                <HeroiconsV1.Outline.trash class="h-6 w-6" />
              </.a>
            </.td>
          </.tr>
        <% end %>
      </tbody>
    </.table>
    """
  end
end
