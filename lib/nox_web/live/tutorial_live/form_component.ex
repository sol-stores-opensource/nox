defmodule NoxWeb.TutorialLive.FormComponent do
  use NoxWeb, :live_component

  alias Nox.Tutorials

  @impl true
  def update(%{tutorial: tutorial} = assigns, socket) do
    tutorial =
      tutorial
      |> Nox.Repo.preload(
        # le_partner: [],
        tutorial_stores: [:store]
        # pages: {from(x in Nox.Repo.TutPage, order_by: [asc: x.position, asc: x.id]), []}
      )

    tutorial =
      tutorial
      |> Map.put(
        :tutorial_stores,
        tutorial.tutorial_stores
        |> Enum.map(fn ts ->
          ts
          |> Nox.Repo.DecafNFT.put_virtual_field(:on_complete_nft_address, :on_complete_nft)
        end)
      )

    changeset = Tutorials.change_tutorial(tutorial)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:tutorial, tutorial)
     |> assign(:changeset, changeset)
     |> on_lifecycle_update()}
  end

  @impl true
  def handle_event("validate", %{"tutorial" => tutorial_params}, socket) do
    changeset =
      socket.assigns.tutorial
      |> Tutorials.change_tutorial(tutorial_params, skip_nft_check: true)
      |> Map.put(:action, :validate)

    socket
    |> assign(changeset: changeset)
    |> NoxWeb.Uploadable.Helpers.validate_cropped_uploads([:logo, :hero_image])
    |> noreply()
  end

  @impl true
  def handle_event("save", %{"tutorial" => tutorial_params}, socket) do
    {socket, tutorial_params} = before_save(socket, tutorial_params)

    save_tutorial(socket, socket.assigns.action, tutorial_params)
  end

  @impl true
  def handle_event("cancel-upload", %{"upload-config" => upload_config, "ref" => ref}, socket) do
    socket
    |> cancel_upload(String.to_existing_atom(upload_config), ref)
    |> noreply()
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

  @impl true
  def handle_event("add_store", _, socket) do
    x = Ecto.Changeset.get_field(socket.assigns.changeset, :tutorial_stores) || []

    changeset =
      socket.assigns.changeset
      |> Ecto.Changeset.put_assoc(
        :tutorial_stores,
        x ++ [%{store_id: "", tutorial_id: socket.assigns.tutorial.id}]
      )

    socket
    |> assign(changeset: changeset)
    |> noreply()
  end

  @impl true
  def handle_event("delete_store", %{"i" => i}, socket) do
    x = Ecto.Changeset.get_field(socket.assigns.changeset, :tutorial_stores) || []

    changeset =
      socket.assigns.changeset
      |> Ecto.Changeset.put_assoc(:tutorial_stores, List.delete_at(x, String.to_integer(i)))

    socket
    |> assign(changeset: changeset)
    |> noreply()
  end

  defp save_tutorial(socket, :edit, tutorial_params) do
    case Tutorials.update_tutorial(socket.assigns.tutorial, tutorial_params) do
      {:ok, _tutorial} ->
        {:noreply,
         socket
         |> put_flash(:info, "Tutorial updated successfully")
         |> push_navigate(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_tutorial(socket, :new, tutorial_params) do
    case Tutorials.create_tutorial(tutorial_params) do
      {:ok, _tutorial} ->
        {:noreply,
         socket
         |> put_flash(:info, "Tutorial created successfully")
         |> push_navigate(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  defp on_lifecycle_update(socket) do
    socket =
      if Map.get(socket.assigns, :uploaded_files) do
        socket
      else
        socket
        |> assign(:uploaded_files, [])
        |> allow_upload(:logo,
          accept: ~w(.png),
          max_entries: 1,
          external: fn entry, socket ->
            Nox.Repo.GCSAsset.presign_upload(
              socket,
              "uploads/tutorial_logos/#{entry.uuid}",
              {Nox.Repo.Tutorial, :logo}
            )
          end
        )
        |> allow_upload(:hero_image,
          accept: ~w(.jpg .jpeg .png),
          max_entries: 1,
          external: fn entry, socket ->
            Nox.Repo.GCSAsset.presign_upload(
              socket,
              "uploads/tutorial_hero_images/#{entry.uuid}",
              {Nox.Repo.Tutorial, :hero_image}
            )
          end
        )
        |> allow_upload(:hero_video,
          accept: ~w(.mp4 .mov .m4v .avi .mpg .mpeg),
          max_entries: 1,
          max_file_size: 3_000_000_000,
          external: fn _entry, socket ->
            Nox.Repo.MuxAsset.presign_upload(socket, {Nox.Repo.Tutorial, :hero_video})
          end
        )
      end

    socket
    |> assign_new(:partner_options, fn -> Tutorials.get_partner_options() end)
    |> assign_new(:store_options, fn -> Tutorials.get_store_options() end)
  end

  defp before_save(socket, params) do
    {socket, params} =
      Nox.Repo.GCSAsset.consume_uploaded_entries_to_params(socket, params,
        scope: Nox.Repo.Tutorial,
        name: :logo
      )

    {socket, params} =
      Nox.Repo.GCSAsset.consume_uploaded_entries_to_params(socket, params,
        scope: Nox.Repo.Tutorial,
        name: :hero_image
      )

    {socket, params} =
      Nox.Repo.MuxAsset.consume_uploaded_entries_to_params(socket, params, name: :hero_video)

    # form will not send if not in the UI, so need to patch
    params = Map.put_new(params, "misc", %{})

    {socket, params}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.form
        :let={f}
        for={@changeset}
        id="tutorial-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.form_field
          type="select"
          options={@partner_options}
          form={f}
          field={:le_partner_id}
          prompt="Select a partner..."
          label="Partner"
          {if @action == :edit, do: %{disabled: "true"}, else: %{}}
        />

        <.form_field type="text_input" form={f} field={:title} placeholder="Title" />

        <.form_field
          type="select"
          options={[
            "Phantom - Wallet connected to tablet": "phantom",
            "Web - Device ID connected to tablet": "web_tuts",
            "Web - Wallet NOT connected to tablet": "web"
          ]}
          form={f}
          field={:opens_in}
          prompt="Select..."
          label="Opens in"
        />

        <hr class="my-7" />

        <NoxWeb.Uploadable.uploadable
          form={f}
          field={:logo}
          label="Logo (any x 200)"
          uploadable={@uploads.logo}
          current={f.data.logo}
          min_height={200}
          output_type="image/png"
          phx-target={@myself}
        />

        <hr class="my-7" />

        <NoxWeb.Uploadable.uploadable
          form={f}
          field={:hero_image}
          can_delete
          label="Hero Image (1170x658)"
          uploadable={@uploads.hero_image}
          current={f.data.hero_image}
          min_width={1170}
          min_height={658}
          phx-target={@myself}
        />

        <hr class="my-7" />

        <NoxWeb.UploadableVideo.uploadable
          form={f}
          field={:hero_video}
          can_delete
          label="Hero Video (provide this OR Hero Image for tablet tiles)"
          uploadable={@uploads.hero_video}
          current={f.data.hero_video}
          phx-target={@myself}
        />

        <hr class="my-7" />

        <.form_field
          type="text_input"
          form={f}
          field={:external_url}
          label="External Tutorial URL (overrides default Pages-based tutorial)"
        />

        <.form_field type="textarea" form={f} field={:description} />

        <.form_field
          type="number_input"
          form={f}
          field={:time_est}
          label="Time Estimation (in minutes)"
        />

        <.form_field
          type="text_input"
          form={f}
          field={:tuts_on_complete_webhook}
          label="External Webhook (called when Templated Tutorial is completed)"
        />

        <.form_field
          type="text_input"
          form={f}
          field={:reward_est}
          label="Reward (e.g. name of the automatic airdrop NFT below)"
        />

        <hr class="my-7" />

        <div class="my-4">
          <div class="flex flex-row items-center justify-end gap-x-4 mb-3">
            <div class="flex-grow">
              <.h5 class="!m-0">Store Availability</.h5>
            </div>
            <.button icon type="button" phx-click="add_store" phx-target={@myself}>
              <HeroiconsV1.Outline.plus class="w-5 h-5" /> Store
            </.button>
          </div>

          <%= inputs_for f, :tutorial_stores, [], fn fp  -> %>
            <div id={fp.id} class="flex flex-row gap-x-4">
              <div class="flex-grow">
                <.form_field
                  type="select"
                  options={@store_options}
                  form={fp}
                  field={:store_id}
                  prompt="Select a store..."
                  label="Store"
                />
              </div>

              <div class="flex-grow">
                <.form_field
                  type="text_input"
                  form={fp}
                  field={:on_complete_nft_address}
                  label="Tutorial Complete NFT"
                />

                <%= if url = Nox.Repo.DecafNFT.image_url(fp.data.on_complete_nft) do %>
                  <div class="mb-3">
                    <img src={url} style="max-width:200px" />
                  </div>
                <% end %>
              </div>

              <div class="mt-1 pt-8">
                <.a
                  to="#"
                  phx-click="delete_store"
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

        <hr class="my-7" />

        <div class="flex flex-row justify-end">
          <.button type="submit" color="primary" label="Save" phx-disable-with="Saving..." />
        </div>
      </.form>
    </div>
    """
  end
end
