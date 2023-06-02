defmodule Nox.Repo.Migrations.AddMiscToStores do
  use Ecto.Migration

  def change do
    alter table(:stores) do
      add :misc, :jsonb
    end
  end
end
