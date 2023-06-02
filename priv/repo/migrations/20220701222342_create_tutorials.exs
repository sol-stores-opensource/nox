defmodule Nox.Repo.Migrations.CreateTutorials do
  use Ecto.Migration

  def change do
    create table(:tutorials) do
      add :title, :text
      add :logo, :jsonb
      add :le_partner_id, references(:le_partners, on_delete: :nothing)

      timestamps()
    end

    create index(:tutorials, [:le_partner_id])
  end
end
