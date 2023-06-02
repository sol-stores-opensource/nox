defmodule Nox.TutorialsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Nox.Tutorials` context.
  """

  @doc """
  Generate a tutorial.
  """
  def tutorial_fixture(attrs \\ %{}) do
    partner = Nox.LearnEarnFixtures.le_partner_fixture()

    {:ok, tutorial} =
      attrs
      |> Enum.into(%{
        title: "some title",
        le_partner_id: partner.id
      })
      |> Nox.Tutorials.create_tutorial()

    Nox.Tutorials.get_tutorial!(tutorial.id)
  end

  @doc """
  Generate a tut_page.
  """
  def tut_page_fixture(attrs \\ %{}) do
    tut = tutorial_fixture()

    attrs =
      attrs
      |> Enum.into(%{
        answers: %{},
        description: "some description",
        position: 42,
        title: "some title",
        tutorial_id: tut.id
      })

    {:ok, tut_page} = Nox.Tutorials.create_tut_page(tut, attrs)

    tut_page
  end
end
