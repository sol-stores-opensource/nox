defmodule Nox.Repo.Migrations.ConvertInternalUsersToUsersAndDrop do
  use Ecto.Migration

  def change do
    drop table(:internal_users)

    alter table(:users) do
      remove :address
      add :auth_data, :jsonb
    end
  end
end
