defmodule NoxWeb.UserLive.FormComponent do
  use NoxWeb, :live_component

  alias Nox.Users

  @impl true
  def update(%{user: user} = assigns, socket) do
    user =
      user
      |> Map.put(:roles, adjust_roles(user))

    changeset = Users.change_user(user)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)}
  end

  def adjust_roles(user) do
    (user.roles || [])
    |> Enum.into([])
    |> Enum.filter(fn {_k, v} -> v end)
    |> Enum.map(fn {k, _v} -> "#{k}" end)
  end

  @impl true
  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset =
      socket.assigns.user
      |> Users.change_user(user_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    roles_param =
      user_params
      |> Map.get("roles")

    user_params =
      case roles_param do
        roles_array when is_list(roles_array) ->
          roles = Map.new(roles_array, fn f -> {f, true} end)
          Map.put(user_params, "roles", roles)

        _ ->
          user_params
      end

    save_user(socket, socket.assigns.action, user_params)
  end

  defp save_user(socket, :edit, user_params) do
    case Users.update_user(socket.assigns.user, user_params) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, "User updated successfully")
         |> push_navigate(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_user(socket, :new, user_params) do
    case Users.create_user(user_params) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, "User created successfully")
         |> push_navigate(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.h4 class="grow"><%= @user.email %></.h4>

      <.form
        :let={f}
        for={@changeset}
        id="tutorial-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.form_field type="text_input" form={f} field={:name} placeholder="Name" />

        <.form_field type="text_input" form={f} field={:email} placeholder="Email" />

        <.form_field
          type="checkbox_group"
          form={f}
          field={:roles}
          label="Roles"
          options={[
            {"Admin", "admin"},
            {"Mailing List Manager", "mailing_list_manager"},
            {"Tutorial Editor", "tutorial_editor"},
            {"Analytics", "analytics"},
            {"Intake", "intake"}
          ]}
        />

        <div class="flex flex-row justify-end">
          <.button type="submit" color="primary" label="Save" phx-disable-with="Saving..." />
        </div>
      </.form>
    </div>
    """
  end
end
