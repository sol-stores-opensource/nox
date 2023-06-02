defmodule Nox.Repo.Migrations.AddTutorialsHeroVideo do
  use Ecto.Migration

  def up do
    alter table(:tutorials) do
      add :hero_video, :jsonb
      remove :hero_video_url
    end

    execute "create unique index tutorials_hero_video_id_uniq_idx on tutorials((hero_video->>'id'))"
  end

  def down do
    alter table(:tutorials) do
      add :hero_video_url, :text
      remove :hero_video
    end
  end
end
