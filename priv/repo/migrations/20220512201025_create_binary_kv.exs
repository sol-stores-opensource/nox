defmodule Nox.Repo.Migrations.CreateBinaryKv do
  use Ecto.Migration

  def change do
    create table(:binary_kv, primary_key: false) do
      add :k, :text, primary_key: true
      add :v, :binary
      add :exp, :timestamptz
      timestamps()
    end
  end
end
