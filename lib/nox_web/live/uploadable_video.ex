defmodule NoxWeb.UploadableVideo do
  use Phoenix.Component
  use PetalComponents

  defp error_to_string(:too_large), do: "Too large"
  defp error_to_string(:too_many_files), do: "You have selected too many files"
  defp error_to_string(:not_accepted), do: "You have selected an unacceptable file type"
  defp error_to_string(:external_client_failure), do: "Failed to upload file"

  attr :form, :any, required: true
  attr :field, :atom, required: true
  attr :label, :string, required: true
  attr :uploadable, :any, required: true
  attr :current, :any, required: true
  attr :"phx-target", :any
  attr :can_delete, :boolean

  def uploadable(assigns) do
    ~H"""
    <.form_label form={@form} field={@field} label={@label} />
    <.live_file_input upload={@uploadable} style="display:none" />
    <.button type="button" onclick={"document.getElementById(#{inspect(@uploadable.ref)}).click();"}>
      Choose File
    </.button>
    <.form_field_error form={@form} field={@field} class="mt-1" />

    <div class="flex flex-row justify-center my-3 w-full">
      <section>
        <%= cond do %>
          <% @uploadable.entries != [] -> %>
            <%= for entry <- @uploadable.entries do %>
              <article id={"video-display-#{entry.uuid}"} class="upload-entry">
                <div>
                  <%= entry.client_name %>
                </div>

                <progress value={entry.progress} max="100"><%= entry.progress %>%</progress>

                <button
                  type="button"
                  phx-click="cancel-upload"
                  phx-target={assigns[:"phx-target"]}
                  phx-value-upload-config={entry.upload_config}
                  phx-value-ref={entry.ref}
                  aria-label="cancel"
                >
                  &times;
                </button>

                <%= for err <- upload_errors(@uploadable, entry) do %>
                  <.alert with_icon color="danger" class="mt-1"><%= error_to_string(err) %></.alert>
                <% end %>
              </article>
            <% end %>
          <% @uploadable.entries == [] && @current -> %>
            <%= if assigns[:can_delete] do %>
              <div class="flex flex-row justify-end">
                <div class="px-2 py-1 border-2 border-red-400 rounded-md">
                  <label class="text-sm">
                    <input
                      id={Phoenix.HTML.Form.input_id(@form, "#{@field}_delete", "delete")}
                      type="checkbox"
                      name={Phoenix.HTML.Form.input_name(@form, "#{@field}_delete")}
                      value="DELETE"
                      phx-update="ignore"
                    /> DELETE
                  </label>
                </div>
              </div>
            <% end %>
            <img
              src={Nox.Repo.MuxAsset.thumbnail_url(@current, %{})}
              class="border-dashed border max-w-full block"
            />
          <% true -> %>
        <% end %>
      </section>
    </div>
    """
  end
end
