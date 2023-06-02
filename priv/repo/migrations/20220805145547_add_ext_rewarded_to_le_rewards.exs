defmodule Nox.Repo.Migrations.AddExtRewardedToLeRewards do
  use Ecto.Migration

  def change do
    alter table(:le_rewards) do
      add :ext_redeemed_at, :timestamptz
    end

    create index(:le_rewards, [:token, :address, :ext_redeemed_at])
  end
end
