defmodule NoxWeb.KioskLobbyLive.Index do
  require Logger
  use NoxWeb, :live_view
  alias Nox.Presence

  @presence_lobby "learn_earn_lobby"
  @presence_admin "learn_earn_admin"

  defmodule EditNameForm do
    use Ecto.Schema
    import Ecto.Changeset

    @primary_key false
    embedded_schema do
      field :sid, :string
      field :config, :string
    end

    def changeset(scope, attrs) do
      scope
      |> cast(attrs, [:config])
      |> validate_required([:sid, :config])
      |> validate_change(:config, fn :config, config ->
        case Jason.decode(config) do
          {:ok, _config_data} ->
            []

          _ ->
            [config: "Check the JSON syntax"]
        end
      end)
    end
  end

  @impl true
  def mount(_params, _session, socket) do
    socket =
      if connected?(socket) do
        Phoenix.PubSub.subscribe(Nox.PubSub, @presence_lobby)
        Phoenix.PubSub.subscribe(Nox.PubSub, @presence_admin)
        :timer.send_interval(:timer.seconds(1), :tick)

        tutorial_map =
          Nox.Tutorials.list_tutorials()
          |> Enum.map(fn x -> {x.id, x} end)
          |> Map.new()

        store_map =
          tutorial_map
          |> Map.values()
          |> Enum.map(fn t -> t.tutorial_stores end)
          |> List.flatten()
          |> Enum.map(fn ts -> ts.store end)
          |> Enum.uniq()
          |> Enum.map(fn x -> {x.id, x} end)
          |> Map.new()

        socket
        |> assign(
          connected?: true,
          tick: 0,
          tutorial_map: tutorial_map,
          store_map: store_map,
          ids: %{},
          ids_list: [],
          logs: %{},
          configs: %{},
          active_log: nil,
          editing_name: nil
        )
        |> handle_joins(Presence.list(@presence_lobby))
        |> sort_ids()
      else
        socket
      end

    socket
    |> okreply()
  end

  @impl true
  def handle_event("force_refresh_all", _, socket) do
    socket.assigns.ids
    |> Map.keys()
    |> Enum.map(fn sid -> force_refresh_sid(sid) end)

    socket
    |> noreply()
  end

  @impl true
  def handle_event("force_refresh", %{"sid" => sid}, socket) do
    force_refresh_sid(sid)

    socket
    |> noreply()
  end

  @impl true
  def handle_event("fetch_logs", %{"sid" => sid}, socket) do
    NoxWeb.Endpoint.broadcast("learn_earn:#{sid}", "execjs", %{
      fun: """
      (async () => {
        const logs = await retrieveLogs(1000);
        const logstr = JSON.stringify(logs);
        console.log('report logs', {bytes: logstr.length});
        channel.push('execjs_reply', {logs}, 60000);
      })();
      """
    })

    socket
    |> assign(active_log: sid)
    |> noreply()
  end

  @impl true
  def handle_event("edit_name", %{"sid" => sid}, socket) do
    changeset =
      %EditNameForm{sid: sid, config: Jason.encode!(socket.assigns.ids[sid].config, pretty: true)}
      |> Ecto.Changeset.change()

    socket
    |> assign(editing_name: changeset)
    |> noreply()
  end

  @impl true
  def handle_event("validate_edit_name", %{"edit_name_form" => attrs}, socket) do
    changeset =
      socket.assigns.editing_name.data
      |> EditNameForm.changeset(attrs)
      |> Map.put(:action, "validate")

    socket
    |> assign(editing_name: changeset)
    |> noreply()
  end

  @impl true
  def handle_event("save_edit_name", %{"edit_name_form" => attrs}, socket) do
    changeset =
      socket.assigns.editing_name.data
      |> EditNameForm.changeset(attrs)

    if changeset.valid? do
      data = Ecto.Changeset.apply_changes(changeset)
      change_tablet_config_for_sid(data.sid, data.config)

      socket
      |> assign(editing_name: nil)
      |> noreply()
    else
      socket
      |> assign(editing_name: changeset)
      |> noreply()
    end
  end

  @impl true
  def handle_event("close_modal", _, socket) do
    socket
    |> assign(active_log: nil, editing_name: nil)
    |> noreply()
  end

  @impl true
  def handle_info(:tick, socket) do
    socket
    |> assign(tick: socket.assigns.tick + 1)
    |> noreply()
  end

  @impl true
  def handle_info(%Phoenix.Socket.Broadcast{event: "presence_diff", payload: diff}, socket) do
    socket
    |> handle_leaves(diff.leaves)
    |> handle_joins(diff.joins)
    |> sort_ids()
    |> noreply()
  end

  @impl true
  def handle_info(
        %Phoenix.Socket.Broadcast{
          event: "execjs_reply",
          payload: %{data: %{"logs" => logs}, sid: sid}
        },
        socket
      ) do
    logs =
      for %{"id" => id, "level" => level, "message" => message, "ts" => ts}
          when is_binary(message) <- logs do
        %{
          id: id,
          level: level,
          message: Jason.decode!(message),
          ts: Timex.from_unix(ts, :millisecond)
        }
      end

    socket
    |> assign(logs: Map.put(socket.assigns.logs, sid, logs))
    |> noreply()
  end

  @impl true
  def handle_info(%Phoenix.Socket.Broadcast{event: _event} = _what, socket) do
    # Logger.warn("#{__MODULE__} IGNORE handle_info event=#{event}")
    # IO.inspect(what, label: "IGNORE", structs: false, limit: :infinity)

    socket
    |> noreply()
  end

  defp handle_joins(socket, joins) do
    Enum.reduce(joins, socket, fn {id, %{metas: [meta | _]}}, socket ->
      assign(socket, :ids, Map.put(socket.assigns.ids, id, update_meta(socket, meta)))
    end)
  end

  defp handle_leaves(socket, leaves) do
    Enum.reduce(leaves, socket, fn {id, _}, socket ->
      assign(socket, :ids, Map.delete(socket.assigns.ids, id))
    end)
  end

  def sort_ids(socket) do
    ids_list =
      socket.assigns.ids
      |> Enum.sort_by(fn {_, v} -> [(v.store || v).name || "", v.name || ""] end, :asc)

    socket
    |> assign(ids_list: ids_list)
  end

  def update_meta(socket, meta) do
    data =
      with config when is_map(config) <- meta[:config] do
        store =
          socket.assigns.store_map
          |> Map.get(config["storeId"])

        %{
          config: config,
          store: store,
          name: config["name"] || "Unknown",
          revision: config["appRevision"] || "norev",
          tutorials:
            config["tutorialIds"]
            |> Enum.map(fn id -> socket.assigns.tutorial_map[id] end)
            |> Enum.filter(& &1)
        }
      else
        _ -> %{name: "Unknown", revision: "norev", tutorials: []}
      end

    online_at =
      with online_at when is_integer(online_at) <- meta[:online_at] do
        online_at
        |> Timex.from_unix(:seconds)
      else
        _ -> nil
      end

    meta
    |> Map.put(:online_at, online_at)
    |> Map.merge(data)
  end

  def force_refresh_sid(sid) do
    NoxWeb.Endpoint.broadcast("learn_earn:#{sid}", "execjs", %{
      fun: """
      console.log("force_refresh");
      window.location.reload(true);
      """
    })
  end

  def change_tablet_config_for_sid(sid, config) do
    %{"name" => name, "tutorialIds" => tutorial_ids, "storeId" => store_id} =
      Jason.decode!(config)

    NoxWeb.Endpoint.broadcast("learn_earn:#{sid}", "execjs", %{
      fun: """
      console.log("set tablet config", #{inspect(config)});
      window.lokiSettings.setName(#{inspect(name)});
      window.lokiSettings.setStoreId(#{inspect(store_id)});
      window.lokiSettings.setTutorialIds(#{inspect(tutorial_ids)});
      """
    })
  end

  def logs(assigns) do
    ~H"""
    <div class="max-w-full">
      <.table>
        <thead>
          <.tr>
            <.th class="whitespace-nowrap w-px">TS</.th>
            <.th class="whitespace-nowrap w-px">Level</.th>
            <.th>Message</.th>
          </.tr>
        </thead>
        <tbody>
          <%= for log <- (@logs || []) do %>
            <.tr id={"log-#{log.id}"}>
              <.td class="font-mono" title={"Entry ##{log.id}"}>
                <%= format_mmddyyyy_time(log.ts, "America/Los_Angeles", false) %>
              </.td>
              <.td class="font-mono">
                <div class={
                  class_names(
                    "text-green-300": log.level == "log",
                    "text-green-300": log.level == "info",
                    "text-red-300": log.level == "warn",
                    "text-red-500": log.level == "error"
                  )
                }>
                  <%= String.upcase(log.level) %>
                </div>
              </.td>
              <.td class="font-mono break-all">
                <div class={
                  class_names(
                    "text-gray-50": log.level == "log",
                    "text-gray-50": log.level == "info",
                    "text-red-300": log.level == "warn",
                    "text-red-500": log.level == "error"
                  )
                }>
                  <%= inspect(log.message) %>
                </div>
              </.td>
            </.tr>
          <% end %>
        </tbody>
      </.table>
    </div>
    """
  end

  @impl true
  def render(%{connected?: true} = assigns) do
    ~H"""
    <div class="flex flex-row gap-x-5 mb-5">
      <.h2 class="grow">Kiosks Live</.h2>
      <.button
        color="danger"
        label="Restart All"
        phx-click="force_refresh_all"
        data-confirm="Refresh ALL tablets.  Are you sure?"
      />
    </div>

    <%= if @active_log do %>
      <div class="dark">
        <.modal max_width="full" title={"Logs for #{@ids[@active_log].name} (#{@active_log})"}>
          <.logs info={@ids[@active_log]} tutorial_map={@tutorial_map} logs={@logs[@active_log]} />
        </.modal>
      </div>
    <% end %>

    <%= if @editing_name do %>
      <div class="dark">
        <.modal title="Edit">
          <.alert color="danger" class="mb-3">
            <p class="text-black">
              <strong>Note:</strong>
              <span>
                Name change will only take effect after you refresh the tablet.
              </span>
            </p>
          </.alert>
          <.form
            :let={f}
            for={@editing_name}
            id="editing-name-form"
            phx-change="validate_edit_name"
            phx-submit="save_edit_name"
          >
            <.form_field type="textarea" form={f} field={:config} placeholder="Config" rows="10" />

            <div class="flex flex-row justify-end">
              <.button type="submit" color="primary" label="Save" phx-disable-with="Saving..." />
            </div>
          </.form>
        </.modal>
      </div>
    <% end %>

    <.table>
      <thead>
        <.tr>
          <.th class="whitespace-nowrap w-px">Store</.th>
          <.th class="whitespace-nowrap w-px">Name</.th>
          <.th class="whitespace-nowrap w-px">Revision</.th>
          <.th class="whitespace-nowrap w-px">Session Since</.th>
          <.th class="whitespace-nowrap w-px">Session ID</.th>
          <.th>State</.th>
          <.th class="whitespace-nowrap w-px"></.th>
          <.th class="whitespace-nowrap w-px"></.th>
        </.tr>
      </thead>
      <tbody>
        <%= for {sid, info} <- @ids_list do %>
          <.tr id={"ids-id-#{info.phx_ref}"}>
            <.td>
              <div class="font-semibold whitespace-nowrap flex flex-row gap-x-2 group">
                <%= (Map.get(info, :store) && info.store.name) || "Unknown" %>
              </div>
            </.td>
            <.td>
              <div class="font-semibold whitespace-nowrap flex flex-row gap-x-2 group">
                <%= info.name %>
                <.a
                  to="#"
                  phx-click="edit_name"
                  phx-value-sid={sid}
                  class="invisible group-hover:visible"
                  title="Edit Name"
                >
                  <HeroiconsV1.Outline.pencil class="h-6 w-6" />
                </.a>
              </div>
            </.td>
            <.td>
              <div class="font-mono">
                <%= info.revision %>
              </div>
            </.td>
            <.td>
              <div class="font-mono" data-tick={@tick} title={format_mmddyyyy_time(info.online_at)}>
                <%= Timex.Format.DateTime.Formatters.Relative.format!(info.online_at, "{relative}") %>
              </div>
            </.td>
            <.td>
              <div class="font-mono">
                <%= case info do %>
                  <% %{session: %{selected_tutorial: %{"name" => _name}}} -> %>
                    <div>
                      <div class="inline-block font-mono text-xs whitespace-nowrap bg-green-300 px-2 py-1 rounded">
                        <%= String.slice(sid, 0..7) %>
                      </div>
                    </div>
                  <% _ -> %>
                    <div>
                      <div class="inline-block font-mono text-xs whitespace-nowrap bg-gray-300 px-2 py-1 rounded">
                        <%= String.slice(sid, 0..7) %>
                      </div>
                    </div>
                <% end %>
              </div>
            </.td>
            <.td>
              <%= if info.name == "Phantom" do %>
                Not tracked
              <% else %>
                <%= if info.tutorials do %>
                  <div>
                    <span class="font-bold">Configured Tutorials:</span>
                    <%= info.tutorials |> Enum.map(& &1.title) |> Enum.join(", ") %>
                  </div>
                <% end %>
                <%= case info do %>
                  <% %{session: %{selected_tutorial: %{"name" => name}}} -> %>
                    <div>
                      <span class="font-bold">Selected Tutorial:</span>
                      <%= name %>
                    </div>
                  <% _ -> %>
                    <div>
                      <span class="font-bold">Kiosk Open!</span>
                    </div>
                <% end %>
                <%= case info do %>
                  <% %{session: %{address: address}} -> %>
                    <div>
                      <span class="font-bold">Wallet:</span>
                      <%= address %>
                    </div>
                  <% _ -> %>
                <% end %>
                <%= case info do %>
                  <% %{session: %{steps: [_|_] = steps} = session} -> %>
                    <div>
                      <span class="font-bold">Steps Completed:</span>
                      <%= case {session |> Map.get(:step_status, %{}) |> Enum.filter(fn {_, v} -> v == "COMPLETE" end) |> Enum.count(), Enum.count(steps)} do %>
                        <% {n, t} -> %>
                          <%= n %> of <%= t %>
                          <%= if n == t do %>
                            🎉
                          <% end %>
                      <% end %>
                    </div>
                  <% _ -> %>
                <% end %>
              <% end %>
            </.td>
            <.td>
              <.a
                to="#"
                phx-click="force_refresh"
                phx-value-sid={sid}
                data-confirm="Refresh tablet.  Are you sure?"
                class="text-red-300 hover:text-red-700"
                title="Force refresh tablet"
              >
                <HeroiconsV1.Outline.stop class="h-6 w-6" />
              </.a>
            </.td>
            <.td>
              <.a
                to="#"
                phx-click="fetch_logs"
                phx-value-sid={sid}
                class="text-gray-500 hover:text-gray-700"
                title="View Logs"
              >
                <HeroiconsV1.Outline.document_text class="h-6 w-6" />
              </.a>
            </.td>
          </.tr>
        <% end %>
      </tbody>
    </.table>
    """
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div></div>
    """
  end
end
