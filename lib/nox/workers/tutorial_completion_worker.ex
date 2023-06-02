defmodule Nox.Workers.TutorialCompletionWorker do
  require Logger

  # alias Nox.Repo

  use Oban.Worker,
    queue: :default,
    priority: 1,
    max_attempts: 5,
    unique: [
      period: :infinity,
      states: [:available, :scheduled, :retryable],
      keys: [:tutorial_store_id, :address, :device_id, :session_id]
    ]

  @impl Oban.Worker
  def perform(%Oban.Job{
        args:
          %{
            "tutorial_store_id" => tutorial_store_id,
            "address" => address,
            "device_id" => device_id,
            "session_id" => session_id
          } = args
      }) do
    tutorial_store = Nox.Tutorials.get_tutorial_store!(tutorial_store_id)
    tutorial = tutorial_store.tutorial

    Logger.info("#{__MODULE__} args=#{inspect(args)}")

    # is there a webhook for this tutorial?
    if tutorial.tuts_on_complete_webhook do
      # partner instructions:
      # 1.  Implement a POST handler that accepts a JSON payload and returns a 200.

      # POST /your_webhook_endpoint?token=TOKEN_YOU_CREATED
      # Content-Type: application/json
      # Body: {
      #   "event": "complete",
      #   "data": {
      #     "session_id": "spaces-tutorial-session-id-to-distinguish-multiple-completions",
      #     "device_id": "optional-if-wallet-not-present-id",
      #     "wallet_address": "abc123"
      #   }
      # }
      # Return a 200

      # 2.  Tell us your secret webhook URL, i.e.:

      # https://yourapp.com/your_webhook_endpoint?token=TOKEN_YOU_CREATED

      # 3.  Your webhook will receive "complete" events allowing you to store/act on them as you wish.

      Nox.Workers.DispatchWebhookWorker.new(%{
        url: tutorial.tuts_on_complete_webhook,
        payload: %{
          event: "complete",
          data: %{
            session_id: session_id,
            device_id: device_id,
            wallet_address: address
          }
        }
      })
      |> Oban.insert()
    end

    case tutorial_store.on_complete_nft do
      %{"id" => id} ->
        Nox.Workers.DecafAirdropWorker.new(%{
          receiver_wallet: address,
          master_nft_mint: id,
          tutorial_store_id: tutorial_store.id
        })
        |> Oban.insert()

      _ ->
        nil
    end

    :ok
  end
end
