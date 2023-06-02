defmodule Nox.LearnEarnFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Nox.LearnEarn` context.
  """

  @doc """
  Generate a le_partner.
  """
  def le_partner_fixture(attrs \\ %{}) do
    {:ok, le_partner} =
      attrs
      |> Enum.into(%{
        name: "some name"
      })
      |> Nox.LearnEarn.create_le_partner()

    le_partner
  end
end
