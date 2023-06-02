defmodule Nox.Repo.Migrations.AddHeroImageHeroVideoUrlToTutorials do
  use Ecto.Migration

  def change do
    alter table(:tutorials) do
      add :hero_image, :jsonb
      add :hero_video_url, :text
      remove :time_est
    end

    alter table(:tutorials) do
      add :time_est, :integer
    end
  end
end
