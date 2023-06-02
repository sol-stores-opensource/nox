defmodule NoxWeb.TutorialLive.PageFormComponent do
  use NoxWeb, :live_component

  alias Nox.Tutorials

  @impl true
  def update(%{tut_page: tut_page} = assigns, socket) do
    changeset = Tutorials.change_tut_page(tut_page)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)
     |> on_lifecycle_update()}
  end

  @impl true
  def handle_event("validate", %{"tut_page" => tut_page_params}, socket) do
    changeset =
      socket.assigns.tut_page
      |> Tutorials.change_tut_page(tut_page_params)
      |> Map.put(:action, :validate)

    socket
    |> assign(changeset: changeset)
    |> NoxWeb.Uploadable.Helpers.validate_cropped_uploads([:image])
    |> noreply()
  end

  @impl true
  def handle_event("save", %{"tut_page" => params}, socket) do
    {socket, params} = before_save(socket, params)

    save_tut_page(socket, socket.assigns.action, params)
  end

  @impl true
  def handle_event("cancel-upload", %{"upload-config" => upload_config, "ref" => ref}, socket) do
    socket
    |> cancel_upload(String.to_existing_atom(upload_config), ref)
    |> noreply()
  end

  @impl true
  def handle_event("add_answer", _, socket) do
    answers = Ecto.Changeset.get_field(socket.assigns.changeset, :answers) || []

    changeset =
      socket.assigns.changeset
      |> Ecto.Changeset.put_embed(:answers, answers ++ [%{answer: "", correct: false}])

    socket
    |> assign(changeset: changeset)
    |> noreply()
  end

  @impl true
  def handle_event("delete_answer", %{"i" => i}, socket) do
    answers = Ecto.Changeset.get_field(socket.assigns.changeset, :answers) || []

    changeset =
      socket.assigns.changeset
      |> Ecto.Changeset.put_embed(:answers, List.delete_at(answers, String.to_integer(i)))

    socket
    |> assign(changeset: changeset)
    |> noreply()
  end

  defp save_tut_page(socket, :edit_page, params) do
    case Tutorials.update_tut_page(socket.assigns.tut_page, params) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Page updated successfully")
         |> push_navigate(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        # IO.inspect(changeset, label: "OOPS")
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_tut_page(socket, :new_page, params) do
    case Tutorials.create_tut_page(socket.assigns.tutorial, params) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Page created successfully")
         |> push_navigate(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  defp on_lifecycle_update(socket) do
    if Map.get(socket.assigns, :uploaded_files) do
      socket
    else
      socket
      |> assign(:uploaded_files, [])
      |> allow_upload(:image,
        accept: ~w(.jpg .jpeg .png),
        max_entries: 1,
        external: fn entry, socket ->
          Nox.Repo.GCSAsset.presign_upload(
            socket,
            "uploads/tut_page_images/#{entry.uuid}",
            {Nox.Repo.TutPage, :image}
          )
        end
      )
      |> allow_upload(:video,
        accept: ~w(.mp4 .mov .m4v .avi .mpg .mpeg),
        max_entries: 1,
        max_file_size: 3_000_000_000,
        external: fn _entry, socket ->
          Nox.Repo.MuxAsset.presign_upload(socket, {Nox.Repo.TutPage, :video})
        end
      )
    end
  end

  defp before_save(socket, params) do
    {socket, params} =
      Nox.Repo.GCSAsset.consume_uploaded_entries_to_params(socket, params,
        scope: Nox.Repo.TutPage,
        name: :image
      )

    {socket, params} =
      Nox.Repo.MuxAsset.consume_uploaded_entries_to_params(socket, params, name: :video)

    # form will not send if not in the UI, so need to patch
    params = Map.put_new(params, "answers", %{})

    {socket, params}
  end

  defp is_content_page?(changeset) do
    Ecto.Changeset.get_field(changeset, :answers) == []
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
          type="text_input"
          form={f}
          field={:title}
          placeholder={
            if is_content_page?(f.source) do
              "Enter the page title..."
            else
              "Enter the question..."
            end
          }
          label={
            if is_content_page?(f.source) do
              "Title"
            else
              "Question"
            end
          }
        />

        <div class="flex justify-end mb-3">
          <%= if is_content_page?(f.source) do %>
            <.button
              id="content_make_question"
              icon
              type="button"
              phx-click="add_answer"
              phx-target={@myself}
            >
              Make this a Question
            </.button>
          <% else %>
            <.button
              id="question_add_answer"
              icon
              type="button"
              phx-click="add_answer"
              phx-target={@myself}
            >
              <HeroiconsV1.Outline.plus class="w-5 h-5" /> Answer
            </.button>
          <% end %>
        </div>

        <%= inputs_for f, :answers, [], fn fp  -> %>
          <div id={fp.id} class="flex flex-row gap-x-4">
            <div class="flex-grow">
              <.text_input form={fp} field={:answer} placeholder="Write an answer..." />
              <.form_field_error form={fp} field={:answer} class="mt-1" />
            </div>

            <div class="mt-2">
              <label class="inline-flex items-center gap-3 text-sm text-gray-900 dark:text-gray-200">
                <.checkbox form={fp} field={:correct} />
                <div>Correct</div>
              </label>
              <.form_field_error form={fp} field={:correct} class="mt-1" />
            </div>

            <div class="mt-1">
              <.a
                to="#"
                phx-click="delete_answer"
                phx-target={@myself}
                phx-value-i={fp.index}
                data-confirm="Are you sure?"
              >
                <HeroiconsV1.Outline.trash class="h-6 w-6" />
              </.a>
            </div>
          </div>
        <% end %>

        <%= if is_content_page?(f.source) do %>
          <NoxWeb.Uploadable.uploadable
            form={f}
            field={:image}
            can_delete
            label="Image (1170x658)"
            uploadable={@uploads.image}
            current={f.data.image}
            min_width={1170}
            min_height={658}
            phx-target={@myself}
          />

          <NoxWeb.UploadableVideo.uploadable
            form={f}
            field={:video}
            can_delete
            label="Video (provide this OR Image for page)"
            uploadable={@uploads.video}
            current={f.data.video}
            phx-target={@myself}
          />

          <.form_field type="textarea" form={f} field={:description} />

          <.form_field
            type="text_input"
            form={f}
            field={:exit_label}
            placeholder="Go to our website"
            label="Exit Label (optional, only makes sense on LAST page)"
          />

          <.form_field
            type="text_input"
            form={f}
            field={:exit_url}
            placeholder="https://..."
            label="Exit URL"
          />
        <% end %>

        <div class="flex flex-row justify-end">
          <.button type="submit" color="primary" label="Save" phx-disable-with="Saving..." />
        </div>
      </.form>
    </div>
    """
  end
end
