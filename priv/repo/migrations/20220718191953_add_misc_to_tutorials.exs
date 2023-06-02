defmodule Nox.Repo.Migrations.AddMiscToTutorials do
  use Ecto.Migration

  def change do
    alter table(:tutorials) do
      add :misc, :jsonb
    end
  end
end
