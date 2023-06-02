defmodule Nox.Repo.Migrations.CreateLeTables do
  use Ecto.Migration

  def change do
    create table(:le_partners) do
      add :name, :text, null: false
      add :api_key, :text, null: false
      timestamps()
    end

    create table(:le_rewards) do
      add :token, :text, null: false
      add :amount, :float, null: false
      add :address, :text, null: false

      add :le_partner_id,
          references(:le_partners, on_delete: :delete_all, on_update: :update_all),
          null: false

      timestamps()
    end

    create unique_index(:le_partners, [:api_key])
    create index(:le_rewards, [:le_partner_id])
    create index(:le_rewards, [:address])
  end
end
