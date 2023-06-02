defmodule Nox.Repo.LePartner do
  use Nox.Schema

  schema "le_partners" do
    field :name, :string
    has_many :tutorials, Repo.Tutorial
    timestamps type: :utc_datetime_usec
  end

  @doc false
  def changeset(group, attrs) do
    group
    |> cast(attrs, [
      :name
    ])
    |> validate_required([:name], message: "Can't be blank")
  end
end
