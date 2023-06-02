defmodule Nox.LearnEarnTest do
  use Nox.DataCase

  alias Nox.LearnEarn

  describe "le_partners" do
    alias Nox.Repo.LePartner

    import Nox.LearnEarnFixtures

    @invalid_attrs %{name: nil}

    test "list_le_partners/0 returns all le_partners" do
      le_partner = le_partner_fixture()
      assert LearnEarn.list_le_partners() == [le_partner]
    end

    test "get_le_partner!/1 returns the le_partner with given id" do
      le_partner = le_partner_fixture()
      assert LearnEarn.get_le_partner!(le_partner.id) == le_partner
    end

    test "create_le_partner/1 with valid data creates a le_partner" do
      valid_attrs = %{name: "some name"}

      assert {:ok, %LePartner{} = le_partner} = LearnEarn.create_le_partner(valid_attrs)
      assert le_partner.name == "some name"
    end

    test "create_le_partner/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = LearnEarn.create_le_partner(@invalid_attrs)
    end

    test "update_le_partner/2 with valid data updates the le_partner" do
      le_partner = le_partner_fixture()
      update_attrs = %{name: "some updated name"}

      assert {:ok, %LePartner{} = le_partner} =
               LearnEarn.update_le_partner(le_partner, update_attrs)

      assert le_partner.name == "some updated name"
    end

    test "update_le_partner/2 with invalid data returns error changeset" do
      le_partner = le_partner_fixture()
      assert {:error, %Ecto.Changeset{}} = LearnEarn.update_le_partner(le_partner, @invalid_attrs)
      assert le_partner == LearnEarn.get_le_partner!(le_partner.id)
    end

    test "delete_le_partner/1 deletes the le_partner" do
      le_partner = le_partner_fixture()
      assert {:ok, %LePartner{}} = LearnEarn.delete_le_partner(le_partner)
      assert_raise Ecto.NoResultsError, fn -> LearnEarn.get_le_partner!(le_partner.id) end
    end

    test "change_le_partner/1 returns a le_partner changeset" do
      le_partner = le_partner_fixture()
      assert %Ecto.Changeset{} = LearnEarn.change_le_partner(le_partner)
    end
  end
end
