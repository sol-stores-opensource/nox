defmodule Nox.Repo.Migrations.DeletePartnerSlugFromLePartners do
  use Ecto.Migration

  def change do
    alter table(:le_partners) do
      remove :partner_slug
    end
  end
end
