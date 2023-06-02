defmodule Nox.Repo.Migrations.DestructChangeLeRewardsBelongToTutorial do
  use Ecto.Migration

  def change do
    execute "delete from le_rewards", ""

    alter table(:le_rewards) do
      remove :le_partner_id
    end

    alter table(:le_rewards) do
      add :tutorial_id,
          references(:tutorials, on_delete: :nothing, on_update: :update_all),
          null: false
    end

    create index(:le_rewards, [:tutorial_id])
  end
end
