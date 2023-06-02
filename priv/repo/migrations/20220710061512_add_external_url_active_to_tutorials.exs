defmodule Nox.Repo.Migrations.AddExternalUrlActiveToTutorials do
  use Ecto.Migration

  def change do
    alter table(:tutorials) do
      add :external_url, :text
      add :active, :boolean, default: false
    end
  end
end
