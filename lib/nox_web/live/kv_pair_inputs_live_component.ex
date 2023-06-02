defmodule NoxWeb.Live.KvPairInputsLiveComponent do
  require Logger
  use NoxWeb, :live_component

  @impl true
  def update(%{form: _, field: _, label: _, help: _, button_text: _} = assigns, socket) do
    socket
    |> assign(assigns)
    |> okreply()
  end

  @impl true
  def handle_event(
        "add_kv_input_pair",
        _,
        %{
          assigns: %{
            form: form,
            field: field
          }
        } = socket
      ) do
    Logger.debug("#{__MODULE__} - add_#{field}")

    %Ecto.Changeset{} = changeset = form.source

    field_value = Ecto.Changeset.get_field(changeset, field) || []

    changeset =
      changeset
      |> Ecto.Changeset.put_embed(field, field_value ++ [%{key: "", value: ""}])

    socket
    |> assign(form: %{form | source: changeset})
    |> noreply()
  end

  @impl true
  def handle_event(
        "del_kv_input_pair",
        %{"i" => i},
        %{
          assigns: %{
            form: form,
            field: field
          }
        } = socket
      ) do
    Logger.debug("#{__MODULE__} - delete_#{field}")

    %Ecto.Changeset{} = changeset = form.source

    field_value = Ecto.Changeset.get_field(changeset, field) || []

    changeset =
      changeset
      |> Ecto.Changeset.put_embed(field, List.delete_at(field_value, String.to_integer(i)))

    socket
    |> assign(form: %{form | source: changeset})
    |> noreply()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="my-4">
      <div class="flex flex-row items-center justify-end gap-x-4 mb-3">
        <div class="flex-grow">
          <.h5 class="!m-0"><%= render_slot(@label) %></.h5>
          <%= render_slot(@help) %>
        </div>
        <.button icon type="button" phx-click="add_kv_input_pair" phx-target={@myself}>
          <HeroiconsV1.Outline.plus class="w-5 h-5" /> <%= render_slot(@button_text) %>
        </.button>
      </div>

      <%= for fp <- inputs_for(@form, @field, []) do %>
        <%= hidden_inputs_for(fp) %>
        <div id={fp.id} class="flex flex-row gap-x-4 mb-2">
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
              phx-click="del_kv_input_pair"
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
    """
  end
end
