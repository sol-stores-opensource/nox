defmodule Nox.Repo.Migrations.CreateInternalUsers do
  use Ecto.Migration

  def change do
    create table(:internal_users) do
      add :email, :text
      timestamps()
    end

    create unique_index(:internal_users, [:email])
  end
end
