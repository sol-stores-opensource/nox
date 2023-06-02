defmodule Nox.Repo.DecafNFT do
  require Logger
  import Ecto.Changeset

  def cast_nft_metadata(changeset, store, from_field, to_field) do
    case changeset do
      %{valid?: false} ->
        changeset

      %{changes: %{^from_field => address}} when is_binary(address) ->
        case Nox.Crypto.Decaf.nft_metadata(store, address) do
          {:ok, %{} = metadata} ->
            data = Map.put(metadata, "id", address)
            Logger.info("#{__MODULE__} #{to_field}=#{inspect(data)}")

            changeset
            |> put_change(to_field, data)

          _ ->
            changeset
            |> add_error(from_field, "invalid nft address")
        end

      %{changes: %{^from_field => nil}} ->
        changeset
        |> put_change(to_field, nil)

      _ ->
        changeset
    end
  end

  def image_url(%{"nftMetadata" => %{"image" => image}}) when is_binary(image), do: image
  def image_url(_), do: nil

  def put_virtual_field(struct, to_field, from_field) do
    case Map.get(struct, from_field) do
      %{"id" => id} ->
        Map.put(struct, to_field, id)

      _ ->
        struct
    end
  end
end
