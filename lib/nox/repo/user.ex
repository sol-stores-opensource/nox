defmodule Nox.Repo.User do
  use Nox.Schema

  @email_regex ~r/^[A-Za-z0-9._%+-+'-]+@[A-Za-z0-9.-]+\.[A-Za-z]+$/

  schema "users" do
    field :auth_data, :map
    field :name, :string
    field :email, :string
    field :roles, :map

    timestamps type: :utc_datetime_usec
  end

  def ensure_changeset(user, attrs) do
    user
    |> accept_email_changeset(attrs)
  end

  def accept_email_changeset(user, attrs) do
    user
    |> cast(attrs, [:email])
    |> validate_required([:email])
    |> validate_email(:email)
    |> update_change(:email, &String.downcase/1)
    |> unique_constraint(:email)
  end

  def admin_changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :email, :roles])
    |> update_change(:email, fn x ->
      if x, do: String.downcase(x)
    end)
    |> validate_email(:email)
    |> validate_length(:name, min: 3, max: 100)
  end

  def email_regex(), do: @email_regex

  def validate_email(changeset, field) do
    changeset
    |> validate_format(field, email_regex(),
      message: "Email is not yet valid.  When done typing check for extra spaces or typos."
    )
  end
end
