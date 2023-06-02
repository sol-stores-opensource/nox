defmodule NoxWeb.LearnEarnChannel do
  require Logger
  use NoxWeb, :channel

  @impl true
  def join("learn_earn:" <> sid, _payload, socket) do
    case Ecto.UUID.cast(sid) do
      {:ok, ^sid} ->
        socket =
          socket
          |> assign(sid: sid)

        {:ok, socket}

      _ ->
        {:error, %{reason: "unauthorized"}}
    end
  end

  @impl true
  def join(_topic, _payload, _socket) do
    {:error, %{reason: "unauthorized"}}
  end

  @impl true
  def terminate(reason, socket) do
    Logger.info(
      "#{__MODULE__} terminate reason=#{inspect(reason)} sid=#{inspect(socket.assigns.sid)}"
    )
  end

  @impl true
  def handle_in("terms_accepted", %{"terms_accepted_ms" => terms_accepted_ms}, socket) do
    Nox.LearnEarn.track_session_terms_accepted!(socket.assigns.sid, terms_accepted_ms)

    {:reply, {:ok, %{ok: true}}, socket}
  end

  @impl true
  def handle_in(
        "selected_tutorial",
        %{"tutorial_store_id" => _} = data,
        %{assigns: %{loki_authorized?: true}} = socket
      ) do
    Nox.LokiSession.put_selected_tutorial(socket.assigns.sid, data)

    Nox.LearnEarn.track_session_collect!(
      socket.assigns.sid,
      "selected_tutorial",
      %{}
    )

    {:noreply, socket}
  end

  @impl true
  def handle_in(
        "collect",
        %{"event" => event} = data,
        %{assigns: %{loki_authorized?: true}} = socket
      ) do
    data =
      data
      |> Map.delete("event")

    Nox.LearnEarn.track_session_collect!(socket.assigns.sid, event, data)

    {:noreply, socket}
  end

  @impl true
  def handle_in("connect", _, socket) do
    session = Nox.LokiSession.get(socket.assigns.sid)

    case session do
      %{selected_tutorial: %{"tutorial_store_id" => tutorial_store_id, "opens_in" => opens_in}}
      when opens_in == "web" ->
        Logger.info(
          "#{__MODULE__} connect track_session_complete tutorial_store_id=#{inspect(tutorial_store_id)} opens_in=#{inspect(opens_in)}"
        )

        Nox.LearnEarn.track_session_start!(socket.assigns.sid)

        Nox.LearnEarn.track_session_complete!(socket.assigns.sid, true)

      _ ->
        nil
    end

    {:reply, {:ok, session}, socket}
  end

  @impl true
  def handle_in("device_ready", %{"address" => address}, socket) do
    Nox.LokiSession.put_address(socket.assigns.sid, address)

    session = Nox.LokiSession.get(socket.assigns.sid)

    broadcast!(socket, "start_tablet", session)

    Nox.LearnEarn.track_session_start!(socket.assigns.sid)

    {:noreply, socket}
  end

  @impl true
  def handle_in("device_ready", %{"device_id" => device_id}, socket) do
    Nox.LokiSession.put_device_id(socket.assigns.sid, device_id)

    session = Nox.LokiSession.get(socket.assigns.sid)

    broadcast!(socket, "start_tablet", session)

    Nox.LearnEarn.track_session_start!(socket.assigns.sid)

    {:noreply, socket}
  end

  @impl true
  def handle_in("tablet_ready", _, socket) do
    session = Nox.LokiSession.get(socket.assigns.sid)

    broadcast!(socket, "start_device", session)

    # schedule_step_status_check()

    {:noreply, socket}
  end

  @impl true
  def handle_in("kiosk_data", _, %{assigns: %{loki_authorized?: true}} = socket) do
    tutorials = Nox.Tutorials.list_tutorials()

    stores =
      tutorials
      |> Enum.map(fn t -> t.tutorial_stores end)
      |> List.flatten()
      |> Enum.map(fn ts -> ts.store end)
      |> Enum.uniq()

    tutorials =
      tutorials
      |> Enum.map(fn x -> Nox.Repo.Tutorial.to_output(x) end)
      |> Enum.filter(& &1)

    stores =
      stores
      |> Enum.map(fn x -> Nox.Repo.Store.to_output(x) end)
      |> Enum.filter(& &1)

    {:reply, {:ok, %{tutorials: tutorials, stores: stores}}, socket}
  end

  @impl true
  def handle_in("kiosk_data", _, socket) do
    {:reply, {:ok, %{tutorials: [], stores: []}}, socket}
  end

  @impl true
  def handle_in("get_tutorials", _, socket) do
    {:reply, {:ok, %{data: []}}, socket}
  end

  @impl true
  def handle_in(
        "execjs_reply",
        data,
        %{assigns: %{sid: sid, loki_authorized?: true}} = socket
      ) do
    NoxWeb.Endpoint.broadcast("learn_earn_admin", "execjs_reply", %{
      data: data,
      sid: sid
    })

    {:noreply, socket}
  end

  # @impl true
  # def handle_info(:step_status, socket) do
  #   Logger.info("#{__MODULE__} :step_status sid=#{inspect(socket.assigns.sid)}")
  #   sid = socket.assigns.sid

  #   Nox.LokiSession.get(sid)
  #   |> Map.get(:step_status, %{})
  #   |> Enum.map(fn {step, status} ->
  #     Nox.LokiSession.broadcast_step_status(sid, step, status)
  #   end)

  #   schedule_step_status_check()

  #   {:noreply, socket}
  # end

  # # thought we needed this, but probably not
  # def schedule_step_status_check() do
  #   Process.send_after(self(), :step_status, :timer.seconds(5))
  # end
end
