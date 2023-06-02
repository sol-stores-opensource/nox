defmodule Nox.Repo.Migrations.RenameApiKeyToPartnerSlug do
  use Ecto.Migration

  def change do
    execute "ALTER TABLE le_partners RENAME api_key TO partner_slug"
  end
end
