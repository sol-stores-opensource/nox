defmodule Nox.LokiSession do
  @prefix "loki:sess:"

  def get(sid) do
    case Ecto.UUID.cast(sid) do
      {:ok, ^sid} ->
        data = Nox.Repo.BinaryKv.get("#{@prefix}#{sid}") || %{}

        data
        |> Map.put(:sid, sid)

      _ ->
        :error
    end
  end

  def put_steps(sid, steps) do
    put(sid, :steps, steps)
  end

  def put_address(sid, address) do
    put(sid, :address, address)
  end

  def put_device_id(sid, device_id) do
    put(sid, :device_id, device_id)
  end

  def put_selected_tutorial(sid, selected_tutorial) do
    put(sid, :selected_tutorial, selected_tutorial)
  end

  def put_step_status(sid, step, status) do
    case get(sid) do
      :error ->
        :error

      data ->
        step_status =
          data
          |> Map.get(:step_status, %{})
          |> Map.put(step, status)

        res = put(sid, :step_status, step_status)

        broadcast_step_status(sid, step, status)

        res
    end
  end

  def del(sid) do
    Nox.Repo.BinaryKv.del("#{@prefix}#{sid}")
  end

  defp put(sid, k, v) do
    case get(sid) do
      :error ->
        :error

      data ->
        data =
          data
          |> Map.put(k, v)

        Nox.Repo.BinaryKv.put("#{@prefix}#{sid}", data, new_ttl())

        data
        |> broadcast_to_presence(sid)
    end
  end

  defp new_ttl() do
    Timex.now() |> Timex.shift(days: 1)
  end

  def broadcast_step_status(sid, step, status) do
    NoxWeb.Endpoint.broadcast("learn_earn:#{sid}", "step", %{step: step, status: status})
  end

  def broadcast_to_presence(session, sid) do
    NoxWeb.Endpoint.broadcast("learn_earn_lobby", "session", %{
      session: session,
      sid: sid
    })

    session
  end
end
