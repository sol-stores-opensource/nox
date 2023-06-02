defmodule NoxWeb.TutorialLive.Show do
  use NoxWeb, :live_view

  alias Nox.Tutorials
  alias Nox.Repo
  alias NoxWeb.Components.Card2ColData

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit_page, %{"tutorial_id" => tutorial_id, "id" => id}) do
    socket
    |> assign(:page_title, page_title(socket.assigns.live_action))
    |> assign(:tutorial, Tutorials.get_tutorial!(tutorial_id))
    |> assign(:tut_page, Tutorials.get_tut_page!(id))
  end

  defp apply_action(socket, :new_page, %{"tutorial_id" => tutorial_id}) do
    socket
    |> assign(:page_title, page_title(socket.assigns.live_action))
    |> assign(:tutorial, Tutorials.get_tutorial!(tutorial_id))
    |> assign(:tut_page, %Repo.TutPage{})
  end

  defp apply_action(socket, live_action, %{"id" => id}) when live_action in [:show, :edit] do
    socket
    |> assign(:page_title, page_title(socket.assigns.live_action))
    |> assign(:tutorial, Tutorials.get_tutorial!(id))
    |> assign(:tut_page, nil)
  end

  @impl true
  def handle_event("close_modal", opts, socket) do
    {:noreply, push_patch(socket, to: close_modal_redirect_to(opts, socket))}
  end

  @impl true
  def handle_event("delete_page", %{"id" => id}, socket) do
    case socket.assigns.tutorial.pages
         |> Enum.find(fn x -> x.id == id end) do
      %Repo.TutPage{} = page ->
        {:ok, _} = Tutorials.delete_tut_page(page)
    end

    socket
    |> assign(:tutorial, Tutorials.get_tutorial!(socket.assigns.tutorial.id))
    |> noreply()
  end

  @impl true
  def handle_event("move_up", %{"i" => i}, socket) do
    i = String.to_integer(i)
    pages = socket.assigns.tutorial.pages
    a = Enum.at(pages, i - 1)
    b = Enum.at(pages, i)

    pages =
      pages
      |> List.replace_at(i, a)
      |> List.replace_at(i - 1, b)

    Tutorials.order_tut_pages(pages)

    socket
    |> assign(:tutorial, Tutorials.get_tutorial!(socket.assigns.tutorial.id))
    |> noreply()
  end

  @impl true
  def handle_event("move_down", %{"i" => i}, socket) do
    i = String.to_integer(i)
    pages = socket.assigns.tutorial.pages
    a = Enum.at(pages, i + 1)
    b = Enum.at(pages, i)

    pages =
      pages
      |> List.replace_at(i, a)
      |> List.replace_at(i + 1, b)

    Tutorials.order_tut_pages(pages)

    socket
    |> assign(:tutorial, Tutorials.get_tutorial!(socket.assigns.tutorial.id))
    |> noreply()
  end

  defp page_title(:show), do: "Tutorial"
  defp page_title(:edit), do: "Edit Tutorial"
  defp page_title(:edit_page), do: "Edit Page"
  defp page_title(:new_page), do: "New Page"

  def close_modal_redirect_to(_opts, socket) do
    ~p"/tutorials/#{socket.assigns.tutorial}"
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-row gap-x-5 mb-5">
      <.h2 class="grow">Tutorial</.h2>
      <.button link_type="live_patch" label="Edit" to={~p"/tutorials/#{@tutorial}/edit"} />
      <.button link_type="live_redirect" label="Back" to={~p"/tutorials"} />
    </div>

    <%= if @live_action in [:edit] do %>
      <.modal title={@page_title} max_width="xl">
        <.live_component
          module={NoxWeb.TutorialLive.FormComponent}
          id={@tutorial.id}
          action={@live_action}
          tutorial={@tutorial}
          return_to={~p"/tutorials/#{@tutorial}"}
        />
      </.modal>
    <% end %>

    <Card2ColData.container>
      <Card2ColData.full_row>
        <:title>
          <%= @tutorial.title %>
        </:title>
        <:right>
          <%= if Nox.Tutorials.is_external?(@tutorial) do %>
            <.badge color="secondary" label="External" variant="outline" />
          <% else %>
            <.badge color="primary" label="Templated" variant="outline" />
          <% end %>
        </:right>
        <:description>
          <%= @tutorial.description %>
        </:description>
      </Card2ColData.full_row>
      <:rows>
        <Card2ColData.data_row>
          <:left>Opens in</:left>
          <:right>
            <%= case @tutorial.opens_in do %>
              <% :phantom -> %>
                Phantom - user scans QR code, the Phantom app opens, wallet address is connected to tablet, and the tutorial is shown.
              <% :web_tuts -> %>
                Web (steps connected) - user scans QR code, Safari/Chrome app opens, and the tutorial is shown.  Wallet address is NOT connected to tablet.  Generated Device ID is used to identify the device.
              <% :web -> %>
                Web (no connection) - user scans QR code, Safari/Chrome app opens, and the tutorial is shown.  Wallet address is NOT connected to tablet.
            <% end %>
            <%=  %>
          </:right>
        </Card2ColData.data_row>
        <%= if Nox.Tutorials.is_external?(@tutorial) do %>
          <Card2ColData.data_row>
            <:left>External Tutorial URL</:left>
            <:right><%= @tutorial.external_url %></:right>
          </Card2ColData.data_row>
        <% end %>
        <Card2ColData.data_row>
          <:left>Partner</:left>
          <:right>
            <.a
              link_type="live_redirect"
              to={~p"/le_partners/#{@tutorial.le_partner}"}
              class="text-purple-500"
            >
              <%= @tutorial.le_partner.name %>
            </.a>
          </:right>
        </Card2ColData.data_row>
        <Card2ColData.data_row>
          <:left>Logo</:left>
          <:right>
            <%= if @tutorial.logo do %>
              <img
                src={Nox.Repo.GCSAsset.public_url(@tutorial.logo)}
                style="width:200px;height:100px"
              />
            <% end %>
          </:right>
        </Card2ColData.data_row>
        <Card2ColData.data_row>
          <:left>Hero Image</:left>
          <:right>
            <%= if @tutorial.hero_image do %>
              <img
                src={Nox.Repo.GCSAsset.public_url(@tutorial.hero_image)}
                style="width:200px;height:100px"
              />
            <% end %>
          </:right>
        </Card2ColData.data_row>
        <Card2ColData.data_row>
          <:left>Hero Video</:left>
          <:right>
            <%= if hero_video_url = Nox.Repo.MuxAsset.thumbnail_url(@tutorial.hero_video, %{}) do %>
              <img src={hero_video_url} style="width:200px;height:100px" />
            <% end %>
          </:right>
        </Card2ColData.data_row>
        <Card2ColData.data_row>
          <:left>Time Estimation</:left>
          <:right><%= if @tutorial.time_est, do: "#{@tutorial.time_est} min" %></:right>
        </Card2ColData.data_row>
        <Card2ColData.data_row>
          <:left>Possible Reward</:left>
          <:right><%= @tutorial.reward_est %></:right>
        </Card2ColData.data_row>
        <Card2ColData.data_row>
          <:left>External Webhook (called when Templated Tutorial is completed)</:left>
          <:right><%= @tutorial.tuts_on_complete_webhook %></:right>
        </Card2ColData.data_row>
        <%= for ts <- @tutorial.tutorial_stores do %>
          <Card2ColData.data_row>
            <:left><%= ts.store.name %> completion NFT</:left>
            <:right>
              <%= case ts.on_complete_nft do %>
                <% %{"id" => id, "nftMetadata" => %{"image" => image}} -> %>
                  <div><%= id %></div>
                  <div><img src={image} style="max-width:300px" /></div>
                <% _ -> %>
              <% end %>
            </:right>
          </Card2ColData.data_row>
        <% end %>
      </:rows>
    </Card2ColData.container>

    <div class="flex flex-row gap-x-5 my-5">
      <.h2 class="grow">Pages</.h2>
      <.button link_type="live_patch" label="New Page" to={~p"/tutorials/#{@tutorial}/pages/new"} />
    </div>

    <%= if @live_action in [:new_page, :edit_page] do %>
      <.modal title={@page_title} max_width="xl">
        <.live_component
          module={NoxWeb.TutorialLive.PageFormComponent}
          id={@tut_page.id || "new"}
          action={@live_action}
          tutorial={@tutorial}
          tut_page={@tut_page}
          return_to={~p"/tutorials/#{@tutorial}"}
        />
      </.modal>
    <% end %>

    <.table>
      <thead>
        <.tr>
          <.th>Page</.th>
          <.th>Preview</.th>

          <.th></.th>
          <.th></.th>
          <.th></.th>
        </.tr>
      </thead>
      <tbody id="tut_pages">
        <%= for {tut_page, i} <- Enum.with_index(@tutorial.pages) do %>
          <.tr id={"tut_page-#{tut_page.id}"}>
            <.td><%= tut_page.position %></.td>
            <.td>
              <%= case Repo.TutPage.to_output(tut_page) do %>
                <% %{
                    type: "question",
                    question: question,
                    answers: answers
                  } -> %>
                  <div class="text-base mb-3">
                    <%= question %>
                  </div>
                  <%= for %{answer: answer, correct: correct} <- answers do %>
                    <div class={
                      class_names([
                        "text-sm",
                        "mb-3",
                        "text-red-500": !correct,
                        "text-green-400": correct
                      ])
                    }>
                      &bull; <%= answer %>
                    </div>
                  <% end %>
                <% %{
                    type: "content_page",
                    title: title,
                    image_url: image_url,
                    video_thumbnail_url: video_thumbnail_url,
                    description: description,
                    exit_label: exit_label,
                    exit_url: exit_url
                  } -> %>
                  <div class="text-base mb-3">
                    <%= title %>
                  </div>
                  <div class="mb-3">
                    <%= if video_thumbnail_url do %>
                      <img src={video_thumbnail_url} style="width:375px;" />
                    <% end %>
                    <%= if video_thumbnail_url && image_url do %>
                      <.alert with_icon color="danger" class="my-1">
                        Both Video and Image are present.  Current frontend logic will prefer Video, but you should
                        delete on to make the choice explicit.
                      </.alert>
                    <% end %>
                    <%= if image_url do %>
                      <img src={image_url} style="width:375px;" />
                    <% end %>
                  </div>
                  <div class="text-sm mb-3">
                    <%= description %>
                  </div>
                  <%= if exit_url do %>
                    <div class="text-sm mb-3">
                      EXIT: <%= exit_label %> -> <%= exit_url %>
                    </div>
                  <% end %>
                <% _ -> %>
                  INVALID
              <% end %>
            </.td>
            <.td class="whitespace-nowrap w-px">
              <div class="flex flex-row justify-end">
                <%= if i > 0 do %>
                  <div
                    class="h-6 w-6 mr-3 cursor-pointer hover:bg-red-300 hover:text-white rounded-full"
                    phx-click="move_up"
                    phx-value-i={i}
                  >
                    <HeroiconsV1.Outline.chevron_up class="h-6 w-6" />
                  </div>
                <% end %>

                <%= if i + 1 < length(@tutorial.pages) do %>
                  <div
                    class="h-6 w-6 cursor-pointer hover:bg-red-300 hover:text-white rounded-full"
                    phx-click="move_down"
                    phx-value-i={i}
                  >
                    <HeroiconsV1.Outline.chevron_down class="h-6 w-6" />
                  </div>
                <% end %>
              </div>
            </.td>

            <.td class="whitespace-nowrap w-px">
              <.a link_type="live_patch" to={~p"/tutorials/#{@tutorial}/pages/#{tut_page}/show/edit"}>
                <HeroiconsV1.Outline.pencil_alt class="h-6 w-6" />
              </.a>
            </.td>
            <.td class="whitespace-nowrap w-px">
              <.a
                to="#"
                phx-click="delete_page"
                phx-value-id={tut_page.id}
                data-confirm="Are you sure?"
              >
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
