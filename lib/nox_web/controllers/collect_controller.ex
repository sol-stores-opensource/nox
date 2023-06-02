defmodule NoxWeb.CollectController do
  require Logger
  use NoxWeb, :controller

  def index(conn, params) do
    # Logger.warn("COLLECT: #{inspect(params)}")

    [request_id] = Plug.Conn.get_resp_header(conn, "x-request-id")

    payload =
      params
      |> Map.put_new("id", request_id)
      |> Map.put_new("ts", Timex.now())

    Nox.Workers.CollectChunkWorker.add(payload)

    conn
    |> resp(200, "ok")
  end
end
