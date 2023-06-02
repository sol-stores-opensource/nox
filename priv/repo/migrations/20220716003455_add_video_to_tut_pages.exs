defmodule Nox.Repo.Migrations.AddVideoToTutPages do
  use Ecto.Migration

  def up do
    alter table(:tut_pages) do
      add :video, :jsonb
      remove :video_url
    end

    execute "create unique index tut_pages_video_id_uniq_idx on tut_pages((video->>'id'))"
  end

  def down do
    alter table(:tut_pages) do
      add :video_url, :text
      remove :video
    end
  end
end
