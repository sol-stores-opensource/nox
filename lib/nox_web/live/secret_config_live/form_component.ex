defmodule NoxWeb.SecretConfigLive.FormComponent do
  use NoxWeb, :live_component

  alias Nox.Repo

  # Form mimics SecretConfig, but uses KVPair embeds needed for the form.
  # The Form is used to validate the form data, and then the form data is
  # used to create or update the SecretConfig.
  defmodule Form do
    use Ecto.Schema
    import Ecto.Changeset

    embedded_schema do
      field :slug, :string
      field :description, :string
      embeds_many :meta, Nox.Repo.KVPair, on_replace: :delete
    end

    def changeset(scope, attrs \\ %{}) do
      scope
      |> cast(attrs, [:slug, :description])
      |> cast_embed(:meta)
    end

    def create(attrs \\ %{}) do
      changeset =
        %__MODULE__{}
        |> changeset(attrs)

      if changeset.valid? do
        rec = apply_changes(changeset)

        case Repo.SecretConfig.create(%{
               slug: rec.slug,
               description: rec.description,
               json_enc:
                 rec.meta
                 |> Enum.map(fn %Nox.Repo.KVPair{key: k, value: v} -> {k, v} end)
                 |> Map.new()
             }) do
          {:ok, s} ->
            {:ok, s}

          {:error, s_changeset} ->
            {:error,
             changeset
             |> Map.put(:errors, s_changeset.errors)
             |> Map.put(:action, :insert)}
        end
      else
        {:error,
         changeset
         |> Map.put(:action, :insert)}
      end
    end

    def update(scope, attrs \\ %{}) do
      changeset =
        scope
        |> changeset(attrs)

      if changeset.valid? do
        rec = apply_changes(changeset)

        s = Repo.SecretConfig.get!(scope.id)

        case Repo.SecretConfig.update(s, %{
               slug: rec.slug,
               description: rec.description,
               json_enc:
                 rec.meta
                 |> Enum.map(fn %Nox.Repo.KVPair{key: k, value: v} -> {k, v} end)
                 |> Map.new()
             }) do
          {:ok, s} ->
            {:ok, s}

          {:error, s_changeset} ->
            {:error,
             changeset
             |> Map.put(:errors, s_changeset.errors)
             |> Map.put(:action, :update)}
        end
      else
        {:error,
         changeset
         |> Map.put(:action, :update)}
      end
    end
  end

  @impl true
  def mount(socket) do
    socket
    |> NoxWeb.Live.KvPairInputs.mount(%{
      name: :kvs,
      changeset_key: :changeset,
      field: :meta
    })
    |> okreply()
  end

  @impl true
  def update(%{form_record: form_record} = assigns, socket) do
    changeset = Form.changeset(form_record)

    socket
    |> assign(assigns)
    |> assign(:form_record, form_record)
    |> assign(:changeset, changeset)
    |> okreply()
  end

  @impl true
  def handle_event("validate", %{"record" => params}, socket) do
    params = params |> Map.put_new("meta", %{})

    changeset =
      socket.assigns.form_record
      |> Form.changeset(params)
      |> Map.put(:action, :validate)

    socket
    |> assign(changeset: changeset)
    |> noreply()
  end

  @impl true
  def handle_event("save", %{"record" => params}, socket) do
    params = params |> Map.put_new("meta", %{})
    save_record(socket, socket.assigns.action, params)
  end

  @impl true
  def handle_event(event, params, socket) do
    NoxWeb.Live.KvPairInputs.handle_event(event, params, socket)
    # socket
    # |> noreply()
  end

  defp save_record(socket, :edit, params) do
    case Form.update(socket.assigns.form_record, params) do
      {:ok, _} ->
        socket
        |> put_flash(:info, "Updated successfully")
        |> push_navigate(to: socket.assigns.return_to)
        |> noreply()

      {:error, %Ecto.Changeset{} = changeset} ->
        socket
        |> assign(:changeset, changeset)
        |> noreply()
    end
  end

  defp save_record(socket, :new, params) do
    case Form.create(params) do
      {:ok, _} ->
        socket
        |> put_flash(:info, "Created successfully")
        |> push_navigate(to: socket.assigns.return_to)
        |> noreply()

      {:error, %Ecto.Changeset{} = changeset} ->
        socket
        |> assign(changeset: changeset)
        |> noreply()
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.form
        :let={f}
        for={@changeset}
        as={:record}
        id="record-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.form_field type="text_input" form={f} field={:slug} label="slug" />
        <.form_field type="textarea" form={f} field={:description} label="description" />

        <NoxWeb.Live.KvPairInputs.kv_pair_inputs
          config={
            %{
              name: :kvs,
              field: :meta
            }
          }
          form={f}
          phx-target={@myself}
        >
          <:label>Encrypted Pairs</:label>
          <:help>
            <.p>
              These are key/value pairs that are encrypted at rest.
            </.p>
          </:help>
          <:button_text>KV</:button_text>
        </NoxWeb.Live.KvPairInputs.kv_pair_inputs>

        <div class="flex flex-row justify-end">
          <.button type="submit" phx-target={@myself} color="primary" label="Save" />
        </div>
      </.form>
    </div>
    """
  end
end
