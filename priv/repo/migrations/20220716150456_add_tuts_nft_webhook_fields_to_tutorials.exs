defmodule Nox.Repo.Migrations.AddTutsNftWebhookFieldsToTutorials do
  use Ecto.Migration

  def change do
    alter table(:tutorials) do
      add :tuts_on_complete_webhook, :text
      add :tuts_on_complete_nft, :text
    end

    alter table(:tut_pages) do
      add :exit_url, :text
      add :exit_label, :text
    end
  end
end
