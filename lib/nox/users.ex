defmodule Nox.Users do
  import Ecto.Query
  alias Nox.Repo
  alias Nox.Repo.User

  def get_by_id(id) do
    case Ecto.UUID.cast(id) do
      {:ok, uuid} ->
        Repo.get(Repo.User, uuid)

      _ ->
        nil
    end
  end

  def ensure_for_email(email) when is_binary(email) do
    %Repo.User{}
    |> Repo.User.ensure_changeset(%{email: email})
    |> Repo.insert(
      on_conflict: from(u in Repo.User, update: [set: [updated_at: fragment("?", u.updated_at)]]),
      conflict_target: :email,
      returning: true
    )
  end

  def exists_by_email?(email) when is_binary(email) do
    email = String.downcase(email)
    query = from u in Repo.User, where: u.email == ^email
    Repo.exists?(query)
  end

  def get_by_email(email) when is_binary(email) do
    email = String.downcase(email)
    query = from u in Repo.User, where: u.email == ^email
    Repo.one(query)
  end

  def add_role!(%Repo.User{} = user, role) when is_binary(role) do
    roles = user.roles || %{}

    roles =
      roles
      |> Map.put(role, true)

    user
    |> Ecto.Changeset.change(%{roles: roles})
    |> Repo.update!()
  end

  def delete_role!(%Repo.User{} = user, role) when is_binary(role) do
    roles = user.roles || %{}

    roles =
      roles
      |> Map.delete(role)

    user
    |> Ecto.Changeset.change(%{roles: roles})
    |> Repo.update!()
  end

  def has_role?(%Repo.User{roles: %{} = roles}, role) when is_binary(role) do
    Map.get(roles, role) == true
  end

  def has_role?(_, _), do: false

  @doc """
  Returns the list of users.

  ## Examples

      iex> list_users()
      [%User{}, ...]

  """
  def list_users do
    from(u in User, order_by: [asc: u.email, asc: u.id])
    |> Repo.all()
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  @doc """
  Creates a user.

  ## Examples

      iex> create_user(%{field: value})
      {:ok, %User{}}

      iex> create_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user(attrs \\ %{}) do
    %Repo.User{}
    |> User.admin_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a user.

  ## Examples

      iex> update_user(user, %{field: new_value})
      {:ok, %User{}}

      iex> update_user(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user(%User{} = user, attrs) do
    user
    |> User.admin_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a user.

  ## Examples

      iex> delete_user(user)
      {:ok, %User{}}

      iex> delete_user(user)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user(%User{} = user, attrs \\ %{}) do
    User.admin_changeset(user, attrs)
  end
end
