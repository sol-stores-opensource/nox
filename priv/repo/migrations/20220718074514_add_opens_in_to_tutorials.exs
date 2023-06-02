defmodule Nox.Repo.Migrations.AddOpensInToTutorials do
  use Ecto.Migration

  def change do
    alter table(:tutorials) do
      add :opens_in, :text
    end

    execute "UPDATE tutorials SET opens_in = 'phantom'", ""

    alter table(:tutorials) do
      modify :opens_in, :text, null: false
    end
  end
end
