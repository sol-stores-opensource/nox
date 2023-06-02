defmodule Nox.Repo.Migrations.UpdateConstraint do
  use Ecto.Migration

  def change do
    execute "alter table le_rewards drop constraint le_rewards_le_partner_id_fkey, add constraint le_rewards_le_partner_id_fkey FOREIGN KEY (le_partner_id) REFERENCES le_partners(id) ON UPDATE CASCADE ON DELETE RESTRICT"
  end
end
