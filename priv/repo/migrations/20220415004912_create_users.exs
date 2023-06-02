defmodule Nox.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :address, :text, null: false
      add :name, :text
      add :email, :text
      add :roles, :jsonb
      timestamps()
    end

    create unique_index(:users, [:address])
  end
end
