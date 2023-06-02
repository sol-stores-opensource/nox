defmodule Nox.Repo.Store do
  use Nox.Schema

  schema "stores" do
    field :decaf_airdrop_api_url, :string
    field :decaf_shop_id, :string
    field :name, :string
    field :slug, :string

    embeds_many :misc, Repo.KVPair, on_replace: :delete

    timestamps type: :utc_datetime_usec
  end

  @doc false
  def changeset(store, attrs) do
    store
    |> cast(attrs, [:name, :slug, :decaf_shop_id, :decaf_airdrop_api_url])
    |> cast_embed(:misc)
    |> validate_required([:name, :slug, :decaf_shop_id, :decaf_airdrop_api_url])
    |> validate_format(:slug, ~r{\A[a-z0-9-]+\z}m,
      message: "must be lowercase alphanumeric (dashes ok)"
    )
  end

  def to_output(%__MODULE__{
        id: id,
        name: name,
        slug: slug,
        misc: misc
      }) do
    %{
      id: id,
      name: name,
      slug: slug,
      misc: misc_to_map(misc)
    }
  end

  def to_output(_), do: nil

  defp misc_to_map(nil), do: %{}

  defp misc_to_map(misc) do
    misc
    |> Enum.map(fn x -> {x.key, x.value} end)
    |> Map.new()
  end
end
