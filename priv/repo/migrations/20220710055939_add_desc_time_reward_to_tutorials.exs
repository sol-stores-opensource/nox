defmodule Nox.Repo.Migrations.AddDescTimeRewardToTutorials do
  use Ecto.Migration

  def change do
    alter table(:tutorials) do
      add :description, :text
      add :time_est, :text
      add :reward_est, :text
    end
  end
end
