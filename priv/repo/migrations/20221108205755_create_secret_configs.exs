defmodule Nox.Repo.Migrations.CreateSecretConfigs do
  use Ecto.Migration

  def change do
    create table(:secret_configs) do
      add :slug, :text, null: false
      add :json_enc, :binary, null: false
      add :description, :text
      add :deleted_at, :timestamptz
      timestamps()
    end

    create unique_index(:secret_configs, [:slug])
    create index(:secret_configs, [:deleted_at])
  end
end
