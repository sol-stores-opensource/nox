defmodule Nox.Tutorials do
  import Ecto.Query, warn: false
  alias Nox.Repo

  alias Nox.Repo.{Tutorial, Store, TutorialStore}
  alias Nox.Repo.TutPage

  def list_stores() do
    from(t in Store,
      order_by: [desc: t.inserted_at, asc: t.id]
    )
    |> Repo.all()
  end

  def list_tutorials do
    from(t in Tutorial, order_by: [asc: fragment("lower(?)", t.title), asc: t.id])
    |> Repo.all()
    |> Repo.preload(le_partner: [], tutorial_stores: [:store])
  end

  def get_tutorial_store!(id) do
    Repo.get!(TutorialStore, id)
    |> Repo.preload(
      tutorial: [
        le_partner: [],
        pages: {from(x in Repo.TutPage, order_by: [asc: x.position, asc: x.id]), []},
        tutorial_stores: [:store]
      ],
      store: []
    )
  end

  def get_tutorial!(id) do
    Repo.get!(Tutorial, id)
    |> Repo.preload(
      le_partner: [],
      tutorial_stores: [:store],
      pages: {from(x in Repo.TutPage, order_by: [asc: x.position, asc: x.id]), []}
    )
  end

  def create_tutorial(attrs \\ %{}) do
    %Tutorial{}
    |> Tutorial.changeset(attrs)
    |> Repo.insert()
  end

  def update_tutorial(%Tutorial{} = tutorial, attrs) do
    tutorial
    |> Tutorial.changeset(attrs)
    |> Repo.update()
  end

  def delete_tutorial(%Tutorial{} = tutorial) do
    Nox.Repo.GCSAsset.delete_attachment(tutorial, :logo)

    Repo.delete(tutorial)
  end

  def change_tutorial(%Tutorial{} = tutorial, attrs \\ %{}, opts \\ []) do
    Tutorial.changeset(tutorial, attrs, opts)
  end

  def is_external?(%Tutorial{external_url: x}) when is_binary(x) and x != "", do: true
  def is_external?(%Tutorial{}), do: false

  # @doc """
  # Returns the list of tut_pages.

  # ## Examples

  #     iex> list_tut_pages()
  #     [%TutPage{}, ...]

  # """

  # def list_tut_pages do
  #   Repo.all(TutPage)
  # end

  @doc """
  Gets a single tut_page.

  Raises `Ecto.NoResultsError` if the Tut page does not exist.

  ## Examples

      iex> get_tut_page!(123)
      %TutPage{}

      iex> get_tut_page!(456)
      ** (Ecto.NoResultsError)

  """
  def get_tut_page!(id), do: Repo.get!(TutPage, id)

  @doc """
  Creates a tut_page.

  ## Examples

      iex> create_tut_page(%{field: value})
      {:ok, %TutPage{}}

      iex> create_tut_page(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_tut_page(%Tutorial{} = tutorial, attrs \\ %{}) do
    {:ok, res} =
      Repo.transaction(fn ->
        %TutPage{tutorial_id: tutorial.id}
        |> TutPage.changeset(attrs)
        |> Repo.insert()
        |> then(fn res ->
          case res do
            {:ok, tut_page} ->
              next_pos =
                from(tp in TutPage,
                  where: tp.tutorial_id == ^tutorial.id,
                  select: coalesce(max(tp.position), 0) + 1
                )
                |> Repo.one!()

              tut_page =
                tut_page
                |> Ecto.Changeset.change(position: next_pos)
                |> Repo.update!()

              {:ok, tut_page}

            other ->
              other
          end
        end)
      end)

    res
  end

  @doc """
  Updates a tut_page.

  ## Examples

      iex> update_tut_page(tut_page, %{field: new_value})
      {:ok, %TutPage{}}

      iex> update_tut_page(tut_page, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_tut_page(%TutPage{} = tut_page, attrs) do
    tut_page
    |> TutPage.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a tut_page.

  ## Examples

      iex> delete_tut_page(tut_page)
      {:ok, %TutPage{}}

      iex> delete_tut_page(tut_page)
      {:error, %Ecto.Changeset{}}

  """
  def delete_tut_page(%TutPage{} = tut_page) do
    {:ok, res} =
      Repo.transaction(fn ->
        del_res = Repo.delete(tut_page)

        tutorial = get_tutorial!(tut_page.tutorial_id)

        order_tut_pages(tutorial.pages)

        del_res
      end)

    res
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking tut_page changes.

  ## Examples

      iex> change_tut_page(tut_page)
      %Ecto.Changeset{data: %TutPage{}}

  """
  def change_tut_page(%TutPage{} = tut_page, attrs \\ %{}) do
    TutPage.changeset(tut_page, attrs)
  end

  def order_tut_pages(tut_pages) do
    Repo.transaction(fn ->
      tut_pages
      |> Enum.with_index()
      |> Enum.each(fn {x, i} ->
        x
        |> Ecto.Changeset.change(position: i + 1)
        |> Repo.update!()
      end)
    end)
  end

  def get_partner_options() do
    from(p in Repo.LePartner, order_by: [asc: p.name])
    |> Repo.all()
    |> Enum.map(fn x -> {x.name, x.id} end)
  end

  def get_store_options() do
    from(p in Repo.Store, order_by: [asc: p.name])
    |> Repo.all()
    |> Enum.map(fn x -> {x.name, x.id} end)
  end

  def get_tuts_data(tutorial_store) do
    tutorial = tutorial_store.tutorial
    store = tutorial_store.store

    pages =
      tutorial.pages
      |> Enum.map(fn p -> TutPage.to_output(p) end)
      |> Enum.filter(& &1)

    %{
      tutorial: Tutorial.to_output(tutorial),
      store: Store.to_output(store),
      pages: pages
    }
  end
end
