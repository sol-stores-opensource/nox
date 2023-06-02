defmodule Nox.Workers.DispatchWebhookWorker do
  require Logger

  use Oban.Worker,
    queue: :default,
    priority: 3,
    max_attempts: 30

  @impl Oban.Worker
  def perform(%Oban.Job{
        args: %{"url" => url, "payload" => payload}
      }) do
    Logger.info("#{__MODULE__} url=#{inspect(url)} payload=#{inspect(payload)}")

    request =
      %HTTPoison.Request{
        method: :post,
        url: url,
        headers: [
          {"content-type", "application/json"}
        ],
        options: [
          timeout: 120_000,
          recv_timeout: 120_000
          #  ssl: [verify: :verify_none]
        ]
      }
      |> Map.put(:body, Jason.encode!(payload))

    response = HTTPoison.request(request)

    with {:ok, %{body: _body, headers: _headers, status_code: status_code}}
         when status_code >= 200 and status_code < 300 <- response do
      :ok
    else
      what ->
        Logger.warn(
          "#{__MODULE__} WEBHOOK_FAILED url=#{inspect(url)} payload=#{inspect(payload)} what=#{inspect(what)}"
        )

        {:error, "webhook failed what=#{inspect(what)}"}
    end
  end
end
