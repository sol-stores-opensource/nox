defmodule Nox.Repo.Migrations.AddAuthDataToInternalUsers do
  use Ecto.Migration

  def change do
    alter table(:internal_users) do
      add :auth_data, :jsonb
    end
  end
end
