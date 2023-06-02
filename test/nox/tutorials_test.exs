defmodule Nox.TutorialsTest do
  use Nox.DataCase

  alias Nox.Tutorials

  describe "tutorials" do
    alias Nox.Repo.Tutorial

    import Nox.TutorialsFixtures
    import Nox.LearnEarnFixtures

    @invalid_attrs %{logo: nil, title: nil}

    test "get_tutorial!/1 returns the tutorial with given id" do
      tutorial = tutorial_fixture()
      assert Tutorials.get_tutorial!(tutorial.id) == tutorial
    end

    test "create_tutorial/1 with valid data creates a tutorial" do
      partner = le_partner_fixture()
      valid_attrs = %{logo: "some logo", title: "some title", le_partner_id: partner.id}

      assert {:ok, %Tutorial{} = tutorial} = Tutorials.create_tutorial(valid_attrs)
      # assert tutorial.logo == "some logo"
      assert tutorial.title == "some title"
    end

    test "create_tutorial/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Tutorials.create_tutorial(@invalid_attrs)
    end

    test "update_tutorial/2 with valid data updates the tutorial" do
      tutorial = tutorial_fixture()
      update_attrs = %{logo: "some updated logo", title: "some updated title"}

      assert {:ok, %Tutorial{} = tutorial} = Tutorials.update_tutorial(tutorial, update_attrs)
      # assert tutorial.logo == "some updated logo"
      assert tutorial.title == "some updated title"
    end

    test "update_tutorial/2 with invalid data returns error changeset" do
      tutorial = tutorial_fixture()
      assert {:error, %Ecto.Changeset{}} = Tutorials.update_tutorial(tutorial, @invalid_attrs)
      assert tutorial == Tutorials.get_tutorial!(tutorial.id)
    end

    test "delete_tutorial/1 deletes the tutorial" do
      tutorial = tutorial_fixture()
      assert {:ok, %Tutorial{}} = Tutorials.delete_tutorial(tutorial)
      assert_raise Ecto.NoResultsError, fn -> Tutorials.get_tutorial!(tutorial.id) end
    end

    test "change_tutorial/1 returns a tutorial changeset" do
      tutorial = tutorial_fixture()
      assert %Ecto.Changeset{} = Tutorials.change_tutorial(tutorial)
    end
  end

  describe "tut_pages" do
    alias Nox.Repo.TutPage
    alias Nox.Repo.TutAnswer

    import Nox.TutorialsFixtures

    @invalid_attrs %{
      description: nil,
      image: nil,
      position: nil,
      title: nil,
      video_url: nil
    }

    test "get_tut_page!/1 returns the tut_page with given id" do
      tut_page = tut_page_fixture()
      assert Tutorials.get_tut_page!(tut_page.id) == tut_page
    end

    test "create_tut_page/1 with valid data creates a tut_page" do
      tut = tutorial_fixture()

      valid_attrs = %{
        answers: [
          %{answer: "some answer", correct: true},
          %{answer: "some other answer", correct: false}
        ],
        description: "some description",
        title: "some title",
        video_url: "some video_url",
        tutorial_id: tut.id
      }

      assert {:ok, %TutPage{} = tut_page} = Tutorials.create_tut_page(tut, valid_attrs)
      assert [%TutAnswer{answer: "some answer"}, _] = tut_page.answers
      assert tut_page.description == "some description"
      assert tut_page.title == "some title"
      assert tut_page.video_url == "some video_url"
    end

    test "create_tut_page/1 with invalid data returns error changeset" do
      tut = tutorial_fixture()
      assert {:error, %Ecto.Changeset{}} = Tutorials.create_tut_page(tut, @invalid_attrs)
    end

    test "update_tut_page/2 with valid data updates the tut_page" do
      tut_page = tut_page_fixture()

      update_attrs = %{
        answers: [
          %{answer: "new answer", correct: false},
          %{answer: "new other answer", correct: true}
        ],
        description: "some updated description",
        image: %{},
        position: 43,
        title: "some updated title",
        video_url: "some updated video_url"
      }

      assert {:ok, %TutPage{} = tut_page} = Tutorials.update_tut_page(tut_page, update_attrs)
      assert [_, %TutAnswer{answer: "new other answer", correct: true}] = tut_page.answers
      # assert tut_page.answers == []
      assert tut_page.description == "some updated description"
      # assert tut_page.image == %{}
      assert tut_page.position == 43
      assert tut_page.title == "some updated title"
      assert tut_page.video_url == "some updated video_url"
    end

    test "update_tut_page/2 with invalid data returns error changeset" do
      tut_page = tut_page_fixture()
      assert {:error, %Ecto.Changeset{}} = Tutorials.update_tut_page(tut_page, @invalid_attrs)
      assert tut_page == Tutorials.get_tut_page!(tut_page.id)
    end

    test "delete_tut_page/1 deletes the tut_page" do
      tut_page = tut_page_fixture()
      assert {:ok, %TutPage{}} = Tutorials.delete_tut_page(tut_page)
      assert_raise Ecto.NoResultsError, fn -> Tutorials.get_tut_page!(tut_page.id) end
    end

    test "change_tut_page/1 returns a tut_page changeset" do
      tut_page = tut_page_fixture()
      assert %Ecto.Changeset{} = Tutorials.change_tut_page(tut_page)
    end
  end
end
