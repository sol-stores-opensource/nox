defmodule NoxWeb.LearnEarnLobbyChannel do
  require Logger
  use NoxWeb, :channel
  alias Nox.Presence

  intercept ["presence_diff", "session"]

  @impl true
  def join("learn_earn_lobby", _payload, socket) do
    socket =
      socket
      |> assign(sid: nil, config: nil)

    {:ok, socket}
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
  def handle_in(
        "set_sid",
        %{"sid" => sid, "config" => config},
        %{assigns: %{sid: previous_sid, loki_authorized?: true}} = socket
      )
      when is_binary(sid) do
    socket =
      socket
      |> assign(sid: sid, config: config)

    if previous_sid do
      Presence.untrack(socket, previous_sid)
    end

    {:ok, _} =
      Presence.track(socket, sid, %{
        online_at: System.system_time(:second),
        config: config,
        session: Nox.LokiSession.get(sid)
      })

    {:noreply, socket}
  end

  @impl true
  def handle_in("set_sid", _, socket) do
    {:noreply, socket}
  end

  # noop presence_diff since kiosks don't need to track presence of other kiosks,
  # and the admin view gets presence of the channel directly
  @impl true
  def handle_out("presence_diff", _payload, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_out(
        "session",
        %{session: session, sid: sid},
        %{assigns: %{sid: sid}} = socket
      ) do
    Presence.update(socket, sid, fn cur ->
      Map.put(cur, :session, session)
    end)

    {:noreply, socket}
  end

  @impl true
  def handle_out("session", _, socket) do
    {:noreply, socket}
  end
end
