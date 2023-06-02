defmodule Nox.Repo.LeReward do
  use Nox.Schema

  schema "le_rewards" do
    field :token, :string
    field :amount, :float
    field :address, :string
    field :ext_redeemed_at, :utc_datetime_usec
    belongs_to :tutorial, Repo.Tutorial
    timestamps type: :utc_datetime_usec
  end

  @doc false
  def changeset(group, attrs) do
    group
    |> cast(attrs, [
      :amount,
      :token,
      :address
    ])
    |> validate_required([:name], message: "Can't be blank")
  end
end
