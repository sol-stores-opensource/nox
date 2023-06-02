defmodule Nox.Repo.Migrations.CreateStores do
  use Ecto.Migration

  def change do
    create table(:stores) do
      add :name, :text, null: false
      add :slug, :text, null: false
      add :decaf_shop_id, :text
      add :decaf_airdrop_api_url, :text

      timestamps()
    end

    create unique_index(:stores, [:slug])
  end
end
