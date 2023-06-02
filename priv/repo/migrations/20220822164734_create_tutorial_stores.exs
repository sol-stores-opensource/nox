defmodule Nox.Repo.Migrations.CreateTutorialStores do
  use Ecto.Migration

  def change do
    create table(:tutorial_stores) do
      add :tutorial_id, references(:tutorials, on_delete: :nothing), null: false
      add :store_id, references(:stores, on_delete: :nothing), null: false
      add :on_complete_nft, :jsonb

      timestamps()
    end

    create unique_index(:tutorial_stores, [:tutorial_id, :store_id])
    create index(:tutorial_stores, [:tutorial_id])
    create index(:tutorial_stores, [:store_id])
  end
end
