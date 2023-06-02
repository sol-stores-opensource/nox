defmodule Nox.LearnEarn do
  @moduledoc """
  The LearnEarn context.
  """

  import Ecto.Query, warn: false
  alias Nox.Repo

  alias Nox.Repo.LePartner
  alias Nox.Repo.TutorialStore

  @doc """
  Returns the list of le_partners.

  ## Examples

      iex> list_le_partners()
      [%LePartner{}, ...]

  """
  def list_le_partners do
    Repo.all(LePartner)
  end

  @doc """
  Gets a single le_partner.

  Raises `Ecto.NoResultsError` if the partner does not exist.

  ## Examples

      iex> get_le_partner!(123)
      %LePartner{}

      iex> get_le_partner!(456)
      ** (Ecto.NoResultsError)

  """
  def get_le_partner!(id), do: Repo.get!(LePartner, id)

  @doc """
  Creates a le_partner.

  ## Examples

      iex> create_le_partner(%{field: value})
      {:ok, %LePartner{}}

      iex> create_le_partner(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_le_partner(attrs \\ %{}) do
    %LePartner{}
    |> LePartner.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a le_partner.

  ## Examples

      iex> update_le_partner(le_partner, %{field: new_value})
      {:ok, %LePartner{}}

      iex> update_le_partner(le_partner, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_le_partner(%LePartner{} = le_partner, attrs) do
    le_partner
    |> LePartner.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a le_partner.

  ## Examples

      iex> delete_le_partner(le_partner)
      {:ok, %LePartner{}}

      iex> delete_le_partner(le_partner)
      {:error, %Ecto.Changeset{}}

  """
  def delete_le_partner(%LePartner{} = le_partner) do
    Repo.delete(le_partner)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking le_partner changes.

  ## Examples

      iex> change_le_partner(le_partner)
      %Ecto.Changeset{data: %LePartner{}}

  """
  def change_le_partner(%LePartner{} = le_partner, attrs \\ %{}) do
    LePartner.changeset(le_partner, attrs)
  end

  def rewards_by_tutorial_id_address(tutorial_id, address) do
    from(lr in Repo.LeReward,
      where: lr.tutorial_id == ^tutorial_id,
      where: lr.address == ^address,
      group_by: [lr.token],
      select: %{token: lr.token, amount: coalesce(sum(lr.amount), 0.0)}
    )
    |> Repo.all()
    |> Enum.map(fn x -> {x.token, x.amount} end)
    |> Map.new()
  end

  def track_reward(tutorial_id, address, token, amount, session_id \\ nil) do
    float_amount = to_float(amount)

    rec =
      %Repo.LeReward{
        amount: float_amount,
        token: token,
        address: address,
        tutorial_id: tutorial_id
      }
      |> Repo.insert!()

    if session_id do
      NoxWeb.Endpoint.broadcast("learn_earn:#{session_id}", "reward", %{
        amount: amount,
        token: token
      })
    end

    rec
  end

  def track_ext_redeemed(address, token) do
    {updated_count, _} =
      from(lr in Repo.LeReward,
        where: lr.address == ^address,
        where: lr.token == ^token,
        where: is_nil(lr.ext_redeemed_at),
        update: [
          set: [ext_redeemed_at: fragment("now()")]
        ]
      )
      |> Repo.update_all([])

    updated_count > 0
  end

  def track_ext_unredeemed_staging(address, token) do
    {updated_count, _} =
      from(lr in Repo.LeReward,
        where: lr.address == ^address,
        where: lr.token == ^token,
        update: [
          set: [ext_redeemed_at: nil]
        ]
      )
      |> Repo.update_all([])

    updated_count > 0
  end

  def collect_properties(%TutorialStore{} = tutorial_store, map \\ %{}) do
    tutorial_store =
      tutorial_store
      |> Repo.preload(store: [], tutorial: [le_partner: []])

    %{
      tutorial_id: tutorial_store.tutorial.id,
      tutorial_title: tutorial_store.tutorial.title,
      store_id: tutorial_store.store.id,
      store_name: tutorial_store.store.name,
      partner_id: tutorial_store.tutorial.le_partner_id,
      partner_name: tutorial_store.tutorial.le_partner.name
    }
    |> Map.merge(map)
  end

  def track_session_terms_accepted!(session_id, terms_accepted_ms) do
    terms_accepted_ms = to_float(terms_accepted_ms)

    payload =
      %{}
      |> Map.put("event", "terms_accepted")
      |> Map.put("type", "learn_and_earn")
      |> Map.put(
        "properties",
        %{
          session_id: session_id,
          terms_accepted_ms: terms_accepted_ms
        }
      )

    Nox.Workers.CollectChunkWorker.nox_add(payload)

    :ok
  end

  def track_session_start!(session_id) do
    case Nox.LokiSession.get(session_id) do
      %{selected_tutorial: %{"tutorial_store_id" => tutorial_store_id}} = session ->
        tutorial_store = Nox.Tutorials.get_tutorial_store!(tutorial_store_id)
        address = Map.get(session, :address)
        device_id = Map.get(session, :device_id)

        payload =
          %{}
          |> Map.put("event", "start")
          |> Map.put("type", "learn_and_earn")
          |> Map.put(
            "properties",
            collect_properties(tutorial_store, %{
              wallet_address: address,
              device_id: device_id,
              session_id: session_id
            })
          )
          |> Map.put("anonymousId", address || device_id)

        Nox.Workers.CollectChunkWorker.nox_add(payload)

        :ok

      _ ->
        :error
    end
  end

  def track_session_step!(session_id, step) do
    case Nox.LokiSession.get(session_id) do
      %{selected_tutorial: %{"tutorial_store_id" => tutorial_store_id}} = session ->
        tutorial_store = Nox.Tutorials.get_tutorial_store!(tutorial_store_id)
        address = Map.get(session, :address)
        device_id = Map.get(session, :device_id)

        payload =
          %{}
          |> Map.put("event", "step")
          |> Map.put("type", "learn_and_earn")
          |> Map.put(
            "properties",
            collect_properties(tutorial_store, %{
              wallet_address: address,
              device_id: device_id,
              session_id: session_id,
              step: step
            })
          )
          |> Map.put("anonymousId", address || device_id)

        Nox.Workers.CollectChunkWorker.nox_add(payload)

        :ok

      _ ->
        :error
    end
  end

  def track_session_external_reward!(session_id, token, amount) do
    case Nox.LokiSession.get(session_id) do
      %{selected_tutorial: %{"tutorial_store_id" => tutorial_store_id}} = session ->
        tutorial_store = Nox.Tutorials.get_tutorial_store!(tutorial_store_id)
        address = Map.get(session, :address)
        device_id = Map.get(session, :device_id)

        amount = to_float(amount)

        payload =
          %{}
          |> Map.put("event", "external_reward")
          |> Map.put("type", "learn_and_earn")
          |> Map.put(
            "properties",
            collect_properties(tutorial_store, %{
              wallet_address: address,
              device_id: device_id,
              session_id: session_id,
              token: token,
              amount: amount
            })
          )
          |> Map.put("anonymousId", address || device_id)

        Nox.Workers.CollectChunkWorker.nox_add(payload)

        :ok

      _ ->
        :error
    end
  end

  def track_session_collect!(session_id, event, data) do
    res =
      case Nox.LokiSession.get(session_id) do
        %{selected_tutorial: %{"tutorial_store_id" => tutorial_store_id}} = session ->
          tutorial_store = Nox.Tutorials.get_tutorial_store!(tutorial_store_id)
          address = Map.get(session, :address)
          device_id = Map.get(session, :device_id)
          {:ok, %{tutorial_store: tutorial_store, address: address, device_id: device_id}}

        _ ->
          case data do
            %{"tutorial_store_id" => tutorial_store_id} ->
              tutorial_store = Nox.Tutorials.get_tutorial_store!(tutorial_store_id)
              {:ok, %{tutorial_store: tutorial_store, address: nil, device_id: nil}}

            _ ->
              :error
          end
      end

    case res do
      {:ok, %{tutorial_store: tutorial_store, address: address, device_id: device_id}} ->
        case {event, data} do
          {event, data}
          when is_binary(event) and event not in ["start", "step", "complete"] and is_map(data) ->
            payload =
              %{}
              |> Map.put("event", event)
              |> Map.put("type", "learn_and_earn")
              |> Map.put(
                "properties",
                collect_properties(tutorial_store, %{
                  wallet_address: address,
                  device_id: device_id,
                  session_id: session_id
                })
                |> Map.merge(data)
              )
              |> Map.put("anonymousId", address || device_id)

            Nox.Workers.CollectChunkWorker.nox_add(payload)

            :ok

          _ ->
            :error
        end

      _ ->
        :error
    end
  end

  def track_session_complete!(session_id, status)
      when status in [true, false] and is_binary(session_id) do
    case Nox.LokiSession.get(session_id) do
      %{selected_tutorial: %{"tutorial_store_id" => tutorial_store_id}} = session ->
        tutorial_store = Nox.Tutorials.get_tutorial_store!(tutorial_store_id)
        address = Map.get(session, :address)
        device_id = Map.get(session, :device_id)

        payload =
          %{}
          |> Map.put("event", "complete")
          |> Map.put("type", "learn_and_earn")
          |> Map.put(
            "properties",
            collect_properties(tutorial_store, %{
              wallet_address: address,
              device_id: device_id,
              session_id: session_id,
              status: status
            })
          )
          |> Map.put("anonymousId", address || device_id)

        Nox.Workers.CollectChunkWorker.nox_add(payload)

        Nox.LokiSession.del(session_id)

        if status && address do
          case tutorial_store.on_complete_nft do
            %{"id" => id} ->
              rewards =
                Nox.LearnEarn.rewards_by_tutorial_id_address(tutorial_store.tutorial.id, address)

              rewarded = Map.get(rewards, id)

              if rewarded == nil do
                # put a marker on the address/nft combo with amount=0 so we know it should be airdropped.
                # TutorialCompletionWorker will trigger the airdrop.
                # DecafAirdropWorker will attempt the airdrop and update amount=1 if successful.
                Nox.LearnEarn.track_reward(tutorial_store.tutorial.id, address, id, 0)
              end

            _ ->
              nil
          end

          Nox.Workers.TutorialCompletionWorker.new(%{
            tutorial_store_id: tutorial_store.id,
            address: address,
            device_id: device_id,
            session_id: session_id
          })
          |> Oban.insert()
        end

        spaces_nft_reward_count = get_spaces_nft_reward_count(address)

        NoxWeb.Endpoint.broadcast("learn_earn:#{session_id}", "complete", %{
          status: status,
          spaces_nft_reward_count: spaces_nft_reward_count
        })

        :ok

      _ ->
        :error
    end
  end

  @doc """
  Returns the number of spaces NFTs that have been rewarded to the user.
  Pass `additional_nfts` to add NFTs that may not exist as currently
  rewarded, but are expected to be so should be considered in the count.
  """
  def get_spaces_nft_reward_count(address, additional_nfts \\ [])

  def get_spaces_nft_reward_count(nil, _), do: 0

  def get_spaces_nft_reward_count(address, additional_nfts) do
    s =
      from(t in Repo.Tutorial,
        where: fragment("?->>'id' is not null", t.on_complete_nft),
        select: fragment("?->>'id'", t.on_complete_nft),
        distinct: true
      )

    nfts =
      from(lr in Repo.LeReward,
        where: lr.address == ^address,
        where: lr.token in subquery(s),
        select: lr.token,
        distinct: true
      )
      |> Repo.all()

    additional_nfts =
      additional_nfts
      |> Enum.filter(fn x ->
        case x do
          str when is_binary(str) and str != "" -> true
          _ -> false
        end
      end)

    nfts = nfts ++ additional_nfts

    nfts
    |> MapSet.new()
    |> MapSet.size()
  end

  defp to_float(f) when is_float(f) do
    f
  end

  defp to_float(str) when is_binary(str) do
    {float_amount, _} = Float.parse(str)
    float_amount
  end

  defp to_float(int) when is_integer(int) do
    int / 1
  end
end
