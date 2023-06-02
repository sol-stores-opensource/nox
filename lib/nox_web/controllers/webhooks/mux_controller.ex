defmodule NoxWeb.Webhooks.MuxController do
  use NoxWeb, :controller

  def mux(conn, params) do
    signature_header = List.first(get_req_header(conn, "mux-signature"))
    raw_body = List.first(conn.assigns.raw_body)

    case Mux.Webhooks.verify_header(
           raw_body,
           signature_header,
           Application.fetch_env!(:mux, :webhook_secret)
         ) do
      :ok ->
        process_webhook(conn, params)

      {:error, message} ->
        conn
        |> put_status(400)
        |> json(%{message: "Error #{message}"})
    end
  end

  def process_webhook(conn, params) do
    # IO.inspect(params, label: "#{__MODULE__} process_webhook")

    case params do
      %{
        "type" => "video.asset.ready",
        "data" => %{"id" => _id, "passthrough" => "enc:" <> _bin = passthrough} = data
      } ->
        case Nox.Repo.MuxAsset.decode_passthrough(passthrough) do
          {schema, field} ->
            Nox.Repo.MuxAsset.update!(schema, field, data)

          _ ->
            nil
        end

      _ ->
        nil
    end

    conn |> send_resp(200, "ok")
  end
end
