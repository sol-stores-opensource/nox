defmodule NoxWeb.Live.KvPairInputs do
  @moduledoc """
  See `NoxWeb.Live.Components.Nft` for an implementation.
  """
  require Logger
  use Phoenix.Component
  use PetalComponents
  use Phoenix.HTML
  import NoxWeb.LiveHelpers

  def mount(
        socket,
        %{
          name: name,
          changeset_key: changeset_key,
          field: field
        } = config
      )
      when is_atom(name) and is_atom(changeset_key) and is_atom(field) do
    socket
    |> assign(name, config)
  end

  def mount(_, _), do: raise("Invalid mount params")

  def handle_event("add_kv_input_pair", %{"config" => config_name}, socket) do
    %{field: field, changeset_key: changeset_key} =
      socket.assigns
      |> Map.get(String.to_existing_atom(config_name))

    Logger.debug("#{__MODULE__} - add_#{field}")

    %Ecto.Changeset{} =
      changeset =
      socket.assigns
      |> Map.get(changeset_key)

    field_value = Ecto.Changeset.get_field(changeset, field) || []

    changeset =
      changeset
      |> Ecto.Changeset.put_embed(field, field_value ++ [%{key: "", value: ""}])

    socket
    |> assign(changeset_key, changeset)
    |> noreply()
  end

  def handle_event("del_kv_input_pair", %{"config" => config_name, "i" => i}, socket) do
    %{field: field, changeset_key: changeset_key} =
      socket.assigns
      |> Map.get(String.to_existing_atom(config_name))

    Logger.debug("#{__MODULE__} - delete_#{field}")

    changeset =
      socket.assigns
      |> Map.get(changeset_key)

    field_value = Ecto.Changeset.get_field(changeset, field) || []

    changeset =
      changeset
      |> Ecto.Changeset.put_embed(field, List.delete_at(field_value, String.to_integer(i)))

    socket
    |> assign(changeset_key, changeset)
    |> noreply()
  end

  attr :config, :any, required: true
  attr :form, :any, required: true
  attr :"phx-target", :any
  slot :label, required: true
  slot :help
  slot :button_text, required: true

  def kv_pair_inputs(assigns) do
    ~H"""
    <div class="my-4">
      <div class="flex flex-row items-center justify-end gap-x-4 mb-3">
        <div class="flex-grow">
          <.h5 class="!m-0"><%= render_slot(@label) %></.h5>
          <%= render_slot(@help) %>
        </div>
        <.button
          icon
          type="button"
          phx-click="add_kv_input_pair"
          phx-target={assigns[:"phx-target"]}
          phx-value-config={@config.name}
        >
          <HeroiconsV1.Outline.plus class="w-5 h-5" /> <%= render_slot(@button_text) %>
        </.button>
      </div>

      <%= inputs_for @form, @config.field, [], fn fp  -> %>
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
              phx-target={assigns[:"phx-target"]}
              phx-value-i={fp.index}
              phx-value-config={@config.name}
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
