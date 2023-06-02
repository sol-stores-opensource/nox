defmodule Nox.Workers.DecafAirdropWorker do
  require Logger

  use Oban.Worker,
    queue: :default,
    priority: 3,
    max_attempts: 30

  import Ecto.Query
  alias Nox.Repo

  @impl Oban.Worker
  def perform(%Oban.Job{
        args: %{
          "receiver_wallet" => receiver_wallet,
          "master_nft_mint" => master_nft_mint,
          "tutorial_store_id" => tutorial_store_id
        }
      }) do
    tutorial_store = Nox.Tutorials.get_tutorial_store!(tutorial_store_id)
    tutorial = tutorial_store.tutorial
    store = tutorial_store.store

    Logger.info(
      "#{__MODULE__} receiver_wallet=#{inspect(receiver_wallet)} master_nft_mint=#{inspect(master_nft_mint)} tutorial_id=#{inspect(tutorial.id)} store_id=#{inspect(store.id)}"
    )

    # send the nft unless already rewarded with it
    rewards = Nox.LearnEarn.rewards_by_tutorial_id_address(tutorial.id, receiver_wallet)
    rewarded = Map.get(rewards, master_nft_mint)

    if rewarded == 0 do
      # send the nft

      case Nox.Crypto.Decaf.airdrop(store, receiver_wallet, master_nft_mint) do
        {:ok, %{"message" => "transaction successful", "transaction" => transaction} = response}
        when is_binary(transaction) ->
          Logger.info(
            "#{__MODULE__} success receiver_wallet=#{inspect(receiver_wallet)} master_nft_mint=#{inspect(master_nft_mint)} tutorial_id=#{inspect(tutorial.id)} transaction=#{inspect(transaction)}"
          )

          # marks our record so we know we've already sent the nft
          from(lr in Repo.LeReward,
            where: lr.address == ^receiver_wallet,
            where: lr.token == ^master_nft_mint,
            where: lr.amount == 0.0,
            update: [
              set: [amount: 1.0]
            ]
          )
          |> Repo.update_all([])

          Nox.Crypto.Decaf.track_airdrop!(
            store,
            master_nft_mint,
            receiver_wallet,
            Nox.LearnEarn.collect_properties(tutorial_store, response)
          )

          :ok

        what ->
          Logger.error(
            "#{__MODULE__} snooze receiver_wallet=#{inspect(receiver_wallet)} master_nft_mint=#{inspect(master_nft_mint)} tutorial_id=#{inspect(tutorial.id)} what=#{inspect(what)}"
          )

          {:snooze, 5}
      end
    else
      :ok
    end
  end
end
