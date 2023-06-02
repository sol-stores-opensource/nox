defmodule NoxWeb.StoreLive.FormComponent do
  use NoxWeb, :live_component

  alias Nox.Stores

  @impl true
  def update(%{store: store} = assigns, socket) do
    changeset = Stores.change_store(store)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("validate", %{"store" => store_params}, socket) do
    changeset =
      socket.assigns.store
      |> Stores.change_store(store_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  @impl true
  def handle_event("save", %{"store" => store_params}, socket) do
    save_store(socket, socket.assigns.action, store_params)
  end

  @impl true
  def handle_event("add_misc", _, socket) do
    misc = Ecto.Changeset.get_field(socket.assigns.changeset, :misc) || []

    changeset =
      socket.assigns.changeset
      |> Ecto.Changeset.put_embed(:misc, misc ++ [%{key: "", value: ""}])

    socket
    |> assign(changeset: changeset)
    |> noreply()
  end

  @impl true
  def handle_event("delete_misc", %{"i" => i}, socket) do
    misc = Ecto.Changeset.get_field(socket.assigns.changeset, :misc) || []

    changeset =
      socket.assigns.changeset
      |> Ecto.Changeset.put_embed(:misc, List.delete_at(misc, String.to_integer(i)))

    socket
    |> assign(changeset: changeset)
    |> noreply()
  end

  defp save_store(socket, :edit, store_params) do
    case Stores.update_store(socket.assigns.store, store_params) do
      {:ok, _store} ->
        {:noreply,
         socket
         |> put_flash(:info, "Store updated successfully")
         |> push_navigate(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_store(socket, :new, store_params) do
    case Stores.create_store(store_params) do
      {:ok, _store} ->
        {:noreply,
         socket
         |> put_flash(:info, "Store created successfully")
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
        id="store-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.form_field type="text_input" form={f} field={:name} placeholder="Store Name" />

        <.form_field type="text_input" form={f} field={:slug} placeholder="Slug" />

        <.form_field type="text_input" form={f} field={:decaf_shop_id} placeholder="Decaf Shop ID" />

        <.form_field
          type="text_input"
          form={f}
          field={:decaf_airdrop_api_url}
          placeholder="Decaf Airdrop API URL"
        />

        <hr class="my-7" />

        <div class="my-4">
          <div class="flex flex-row items-center justify-end gap-x-4 mb-3">
            <div class="flex-grow">
              <.h5 class="!m-0">Misc Key/Value Pairs</.h5>
              <.p>
                These are key/value pairs that can be used to store additional data.
              </.p>
            </div>
            <.button icon type="button" phx-click="add_misc" phx-target={@myself}>
              <HeroiconsV1.Outline.plus class="w-5 h-5" /> Misc
            </.button>
          </div>

          <%= inputs_for f, :misc, [], fn fp  -> %>
            <div id={fp.id} class="flex flex-row gap-x-4">
              <div class="flex-grow">
                <.text_input form={fp} field={:key} placeholder="KEY" />
                <.form_field_error form={fp} field={:key} class="mt-1" />
              </div>

              <div class="flex-grow">
                <.text_input form={fp} field={:value} placeholder="VALUE" />
                <.form_field_error form={fp} field={:value} class="mt-1" />
              </div>

              <div class="mt-1">
                <.a
                  to="#"
                  phx-click="delete_misc"
                  phx-target={@myself}
                  phx-value-i={fp.index}
                  data-confirm="Are you sure?"
                >
                  <HeroiconsV1.Outline.trash class="h-6 w-6" />
                </.a>
              </div>
            </div>
          <% end %>
        </div>

        <div class="flex flex-row justify-end">
          <.button type="submit" color="primary" label="Save" phx-disable-with="Saving..." />
        </div>
      </.form>
    </div>
    """
  end
end
