defmodule Nox.Repo.Migrations.CreateTutPages do
  use Ecto.Migration

  def change do
    create table(:tut_pages) do
      add :position, :integer, null: false, default: 0
      add :title, :text, null: false
      add :description, :text
      add :video_url, :text
      add :image, :jsonb
      add :answers, :jsonb
      add :tutorial_id, references(:tutorials, on_delete: :nothing), null: false

      timestamps()
    end

    create index(:tut_pages, [:tutorial_id])
  end
end
