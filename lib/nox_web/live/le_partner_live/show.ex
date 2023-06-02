defmodule NoxWeb.LePartnerLive.Show do
  use NoxWeb, :live_view

  alias Nox.LearnEarn
  alias NoxWeb.Components.Card2ColData

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:le_partner, LearnEarn.get_le_partner!(id))}
  end

  @impl true
  def handle_event("close_modal", _, socket) do
    {:noreply,
     push_patch(socket,
       to: ~p"/le_partners/#{socket.assigns.le_partner}"
     )}
  end

  defp page_title(:show), do: "Show Partner"
  defp page_title(:edit), do: "Edit Partner"

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-row gap-x-5 mb-5">
      <.h2 class="grow">Show Partner</.h2>
      <.button link_type="live_patch" label="Edit" to={~p"/le_partners/#{@le_partner}/edit"} />
      <.button link_type="live_redirect" label="Back" to={~p"/le_partners"} />
    </div>

    <%= if @live_action in [:edit] do %>
      <.modal title={@page_title}>
        <.live_component
          module={NoxWeb.LePartnerLive.FormComponent}
          id={@le_partner.id}
          action={@live_action}
          le_partner={@le_partner}
          return_to={~p"/le_partners/#{@le_partner}"}
        />
      </.modal>
    <% end %>

    <Card2ColData.container>
      <Card2ColData.full_row>
        <:title>
          <%= @le_partner.name %>
        </:title>
      </Card2ColData.full_row>
    </Card2ColData.container>
    """
  end
end
