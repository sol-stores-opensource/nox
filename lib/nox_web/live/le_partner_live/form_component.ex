defmodule NoxWeb.LePartnerLive.FormComponent do
  use NoxWeb, :live_component

  alias Nox.LearnEarn

  @impl true
  def update(%{le_partner: le_partner} = assigns, socket) do
    changeset = LearnEarn.change_le_partner(le_partner)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("validate", %{"le_partner" => le_partner_params}, socket) do
    changeset =
      socket.assigns.le_partner
      |> LearnEarn.change_le_partner(le_partner_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"le_partner" => le_partner_params}, socket) do
    save_le_partner(socket, socket.assigns.action, le_partner_params)
  end

  defp save_le_partner(socket, :edit, le_partner_params) do
    case LearnEarn.update_le_partner(socket.assigns.le_partner, le_partner_params) do
      {:ok, _le_partner} ->
        {:noreply,
         socket
         |> put_flash(:info, "Partner updated successfully")
         |> push_navigate(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_le_partner(socket, :new, le_partner_params) do
    case LearnEarn.create_le_partner(le_partner_params) do
      {:ok, _le_partner} ->
        {:noreply,
         socket
         |> put_flash(:info, "Partner created successfully")
         |> push_navigate(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.form
        :let={f}
        for={@changeset}
        id="le_partner-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
        class="phx-submit-loading:pointer-events-none"
      >
        <.form_field type="text_input" form={f} field={:name} placeholder="Partner Name" />

        <div class="flex flex-row justify-end">
          <.button
            type="submit"
            color="primary"
            label="Save"
            phx-disable-with="Saving..."
            class="phx-submit-loading:animate-pulse"
          />
        </div>
      </.form>
    </div>
    """
  end
end
