defmodule Nox.Repo.SecretConfig do
  use Nox.Schema
  import Nox.Repo, only: [broadcast_record: 3]

  schema "secret_configs" do
    field :slug, :string
    field :description, :string
    field :json_enc, Nox.Encrypted.Map
    field :deleted_at, :utc_datetime_usec

    timestamps type: :utc_datetime_usec
  end

  @doc false
  def changeset(record, attrs \\ %{}) do
    record
    |> cast(attrs, [
      :slug,
      :description,
      :json_enc,
      :deleted_at
    ])
    |> validate_required([:slug, :json_enc], message: "Can't be blank")
    |> validate_format(:slug, ~r/^[a-z0-9-]+$/,
      message: "Only lowercase letters, numbers, and dashes are allowed"
    )
    |> unique_constraint(:slug, name: :secret_configs_slug_index)
  end

  use Nox.Repo.Standard, tombstone: true

  def get_by_slug!(slug) do
    from(
      sc in __MODULE__,
      where: sc.slug == ^slug,
      where: is_nil(sc.deleted_at)
    )
    |> Repo.one!()
  end

  def get_by_slug(slug) do
    from(
      sc in __MODULE__,
      where: sc.slug == ^slug,
      where: is_nil(sc.deleted_at)
    )
    |> Repo.one()
  end
end
