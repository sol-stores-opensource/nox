defmodule Nox.Repo.KVPair do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :key, :string
    field :value, :string
  end

  def changeset(scope, attrs) do
    scope
    |> cast(attrs, __MODULE__.__schema__(:fields))
    |> validate_required(__MODULE__.__schema__(:fields))
  end
end
