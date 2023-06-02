defmodule Nox.Repo.TutorialStore do
  use Nox.Schema

  schema "tutorial_stores" do
    field :on_complete_nft, :map
    field :on_complete_nft_address, :string, virtual: true

    belongs_to :tutorial, Repo.Tutorial
    belongs_to :store, Repo.Store

    timestamps type: :utc_datetime_usec
  end

  @doc false
  def changeset(tutorial_store, attrs, opts \\ []) do
    tutorial_store =
      tutorial_store
      |> Repo.preload(store: [])

    tutorial_store
    |> cast(attrs, [
      :store_id,
      :on_complete_nft_address
    ])
    |> validate_required([
      :store_id
    ])
    |> then(fn c ->
      if Keyword.get(opts, :skip_nft_check) == true do
        c
      else
        store =
          c
          |> get_field(:store_id)
          |> Nox.Stores.get_store!()

        c
        |> Repo.DecafNFT.cast_nft_metadata(
          store,
          :on_complete_nft_address,
          :on_complete_nft
        )
      end
    end)
  end

  def to_output(
        %__MODULE__{
          id: id,
          on_complete_nft: on_complete_nft
        } = tutorial_store
      ) do
    %{
      id: id,
      store: Nox.Repo.Store.to_output(tutorial_store.store),
      on_complete_nft:
        case on_complete_nft do
          %{"id" => id, "nftMetadata" => %{"image" => image}} ->
            %{"id" => id, "image" => image}

          _ ->
            nil
        end
    }
  end

  def to_output(_), do: nil
end
