defmodule NoxWeb.TutorialLive.Index do
  use NoxWeb, :live_view

  alias Nox.Tutorials
  alias Nox.Repo.Tutorial

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :tutorials, list_tutorials())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Tutorial")
    |> assign(:tutorial, Tutorials.get_tutorial!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Tutorial")
    |> assign(:tutorial, %Tutorial{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Tutorials")
    |> assign(:tutorial, nil)
  end

  @impl true
  def handle_event("close_modal", opts, socket) do
    {:noreply, push_patch(socket, to: close_modal_redirect_to(opts, socket))}
  end

  defp list_tutorials do
    Tutorials.list_tutorials()
  end

  defp close_modal_redirect_to(_opts, _socket) do
    ~p"/tutorials"
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-row gap-x-5 mb-5">
      <.h2 class="grow">Listing Tutorials</.h2>
      <.button link_type="live_patch" label="New Tutorial" to={~p"/tutorials/new"} />
    </div>

    <%= if @live_action in [:new, :edit] do %>
      <.modal title={@page_title} max_width="xl">
        <.live_component
          module={NoxWeb.TutorialLive.FormComponent}
          id={@tutorial.id || :new}
          action={@live_action}
          tutorial={@tutorial}
          return_to={~p"/tutorials"}
        />
      </.modal>
    <% end %>

    <.table>
      <thead>
        <.tr>
          <.th>Title</.th>
          <.th>Opens in</.th>
          <.th>Logo</.th>
          <.th>Store Availability</.th>
          <.th>Partner</.th>

          <.th></.th>
        </.tr>
      </thead>
      <tbody id="tutorials">
        <%= for tutorial <- @tutorials do %>
          <.tr id={"tutorial-#{tutorial.id}"}>
            <.td>
              <.a link_type="live_redirect" to={~p"/tutorials/#{tutorial}"} class="text-purple-500">
                <%= tutorial.title %>
              </.a>
              <div class="mt-1">
                <%= if Nox.Tutorials.is_external?(tutorial) do %>
                  <.badge color="secondary" label="External" variant="outline" />
                <% else %>
                  <.badge color="primary" label="Templated" variant="outline" />
                <% end %>
              </div>
            </.td>
            <.td>
              <%= String.upcase("#{tutorial.opens_in}") %>
            </.td>
            <.td>
              <%= if tutorial.logo do %>
                <img src={Nox.Repo.GCSAsset.public_url(tutorial.logo)} style="max-width:200px" />
              <% end %>
            </.td>
            <.td>
              <%= for ts <- tutorial.tutorial_stores do %>
                <%= ts.store.name %>
                <%= case ts.on_complete_nft do %>
                  <% %{"id" => id, "nftMetadata" => %{"image" => image}} -> %>
                    <div class="break-all"><%= id %></div>
                    <div><img src={image} style="max-width:120px" /></div>
                  <% _ -> %>
                <% end %>
              <% end %>
            </.td>
            <.td>
              <%= if tutorial.le_partner do %>
                <%= tutorial.le_partner.name %>
              <% end %>
            </.td>

            <.td class="whitespace-nowrap w-px">
              <.a link_type="live_patch" to={~p"/tutorials/#{tutorial}/edit"}>
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
