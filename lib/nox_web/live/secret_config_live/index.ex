defmodule NoxWeb.SecretConfigLive.Index do
  use NoxWeb, :live_view

  alias Nox.Repo
  require Nox.Repo.SecretConfig

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Repo.SecretConfig.subscribe()
    end

    socket
    |> assign(:records, Repo.SecretConfig.list())
    |> okreply()
  end

  @impl true
  def handle_params(params, _url, socket) do
    socket
    |> apply_action(socket.assigns.live_action, params)
    |> noreply()
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    record = Repo.SecretConfig.get!(id)

    socket
    |> assign(:page_title, "Edit")
    |> assign(:form_record, %NoxWeb.SecretConfigLive.FormComponent.Form{
      id: record.id,
      slug: record.slug,
      description: record.description,
      meta:
        record.json_enc
        |> Enum.map(fn {k, v} -> %Nox.Repo.KVPair{key: k, value: v} end)
    })
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New")
    |> assign(:form_record, %NoxWeb.SecretConfigLive.FormComponent.Form{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "List")
    |> assign(:form_record, nil)
  end

  @impl true
  def handle_event("close_modal", _opts, socket) do
    socket
    |> push_patch(to: ~p"/secret_configs")
    |> noreply()
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    record =
      socket.assigns.records
      |> Enum.find(fn r -> r.id == id end)

    records = for %{id: record_id} = r when record_id != id <- socket.assigns.records, do: r

    {:ok, _} = Repo.SecretConfig.delete(record)

    socket
    |> assign(records: records)
    |> noreply()
  end

  @impl true
  def handle_info(
        %Phoenix.Socket.Broadcast{
          topic: Repo.SecretConfig.topic(),
          event: "updated",
          payload: %{record: record}
        },
        socket
      ) do
    records =
      for r <- socket.assigns.records do
        if r.id == record.id do
          record
        else
          r
        end
      end

    socket
    |> assign(records: records)
    |> put_flash(:info, "#{record.id} was updated")
    |> noreply()
  end

  @impl true
  def handle_info(
        %Phoenix.Socket.Broadcast{
          topic: Repo.SecretConfig.topic(),
          event: "created",
          payload: %{record: record}
        },
        socket
      ) do
    records = [record | socket.assigns.records]

    socket
    |> assign(records: records)
    |> put_flash(:info, "#{record.id} was created")
    |> noreply()
  end

  @impl true
  def handle_info(
        %Phoenix.Socket.Broadcast{
          topic: Repo.SecretConfig.topic(),
          event: "deleted",
          payload: %{record: record}
        },
        socket
      ) do
    records =
      socket.assigns.records
      |> Enum.filter(fn r -> r.id != record.id end)

    socket
    |> assign(records: records)
    |> put_flash(:info, "#{record.id} was deleted")
    |> noreply()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-row gap-x-5 mb-5">
      <div class="grow">
        <.h2>Secret Configs</.h2>
        <.p>Key/Value pairs idenitified by slug and encrypted at rest.</.p>
      </div>
      <div>
        <.button link_type="live_patch" label="New" to={~p"/secret_configs/new"} />
      </div>
    </div>

    <%= if @live_action in [:new, :edit] do %>
      <.modal title={@page_title} max_width="xl">
        <.live_component
          module={NoxWeb.SecretConfigLive.FormComponent}
          id={@form_record.slug || :new}
          action={@live_action}
          form_record={@form_record}
          return_to={~p"/secret_configs"}
        />
      </.modal>
    <% end %>

    <.table>
      <thead>
        <.tr>
          <.th>slug</.th>
          <.th></.th>
          <.th></.th>
        </.tr>
      </thead>
      <tbody id="records">
        <%= for record <- @records do %>
          <.tr id={"record-#{record.id}"}>
            <.td><%= record.slug %></.td>
            <.td class="whitespace-nowrap w-px">
              <.a link_type="live_patch" to={~p"/secret_configs/#{record}/edit"}>
                <HeroiconsV1.Outline.pencil_alt class="h-6 w-6" />
              </.a>
            </.td>
            <.td class="whitespace-nowrap w-px">
              <.a to="#" phx-click="delete" phx-value-id={record.id} data-confirm="Are you sure?">
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
