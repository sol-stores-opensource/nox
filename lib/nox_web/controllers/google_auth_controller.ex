defmodule NoxWeb.GoogleAuthController do
  use NoxWeb, :controller
  alias Nox.Repo

  @doc """
  `index/2` handles the callback from Google Auth API redirect.
  """
  def index(conn, %{"code" => code}) do
    auth_domain = Application.fetch_env!(:nox, :google_auth_domain)

    with {:ok, %{access_token: access_token}} <- ElixirAuthGoogle.get_token(code, conn),
         {:ok, %{email: email, email_verified: true, hd: ^auth_domain} = data} =
           ElixirAuthGoogle.get_user_profile(access_token),
         {:ok, %Repo.User{} = user} <- Nox.Users.ensure_for_email(email) do
      user
      |> Ecto.Changeset.change(%{auth_data: data})
      |> Repo.update!()

      conn
      |> put_session("live_socket_id", "users_socket:#{user.id}")
      |> put_session("current_user", user.id)
      |> put_flash(:info, "Logged in as #{user.email}")
    else
      _ ->
        conn
        |> put_flash(:error, "Could not log in.")
    end
    |> redirect(to: "/")
  end
end
