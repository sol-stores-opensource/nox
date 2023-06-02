defmodule Nox.Repo.Migrations.AddOnCompleteNftToTutorials do
  use Ecto.Migration

  def up do
    alter table(:tutorials) do
      add :on_complete_nft, :jsonb
      remove :tuts_on_complete_nft
    end
  end

  def down do
    alter table(:tutorials) do
      add :tuts_on_complete_nft, :text
      remove :on_complete_nft
    end
  end
end
