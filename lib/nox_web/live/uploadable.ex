defmodule NoxWeb.Uploadable do
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
  attr :min_width, :integer
  attr :min_height, :integer
  attr :output_type, :string
  attr :can_delete, :boolean

  def uploadable(assigns) do
    assigns =
      assigns
      |> assign_new(:min_width, fn -> nil end)
      |> assign_new(:min_height, fn -> nil end)

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
              <%= if String.starts_with?(entry.client_name, "(cropped)") do %>
                <article id={"img-display-#{entry.uuid}"} class="upload-entry">
                  <figure>
                    <.live_img_preview
                      entry={entry}
                      class="border-dashed border max-w-full block"
                      style="max-height:#{@min_height}px;"
                    />
                  </figure>

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
              <% else %>
                <div
                  id={"img-editor-#{entry.uuid}"}
                  phx-hook="LiveImgEditor"
                  phx-target={assigns[:"phx-target"]}
                  data-phx-upload-ref={entry.upload_ref}
                  data-phx-entry-ref={entry.ref}
                  data-phx-update="ignore"
                  data-min-width={@min_width}
                  data-min-height={@min_height}
                  data-output-type={assigns[:output_type]}
                >
                  <div class="flex flex-row gap-x-2 items-center my-3">
                    <div
                      data-hook-el="snap_left"
                      class="w-[30px] h-[30px] border rounded-sm border-black cursor-pointer"
                    >
                      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
                        <style>
                          tspan { white-space:pre }.shp0 { fill: #000000 }
                        </style>
                        <path class="shp0" d="M13 12L24 12L24 90L13 90L13 12Z" /><path
                          class="shp0"
                          d="M31.3 51.6L42.86 46.16C43.18 46.03 43.53 46 43.91 46.08C44.29 46.17 44.48 46.32 44.48 46.53L44.48 50.01L82.04 50.01C82.32 50.01 82.55 50.06 82.73 50.15C82.91 50.24 83 50.36 83 50.51L83 53.49C83 53.64 82.91 53.75 82.73 53.85C82.55 53.94 82.32 53.99 82.04 53.99L44.48 53.99L44.48 57.47C44.48 57.67 44.29 57.82 43.91 57.92C43.53 58 43.18 57.97 42.86 57.82L31.3 52.33C31.1 52.22 31 52.1 31 51.95C31 51.82 31.1 51.7 31.3 51.6L31.3 51.6Z"
                        />
                      </svg>
                    </div>
                    <div
                      data-hook-el="snap_right"
                      class="w-[30px] h-[30px] border rounded-sm border-black cursor-pointer"
                    >
                      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
                        <style>
                          tspan { white-space:pre }.shp0 { fill: #000000 }
                        </style>
                        <path class="shp0" d="M76 12L87 12L87 90L76 90L76 12Z" /><path
                          class="shp0"
                          d="M68.7 51.6L57.14 46.16C56.82 46.03 56.47 46 56.09 46.08C55.71 46.17 55.52 46.32 55.52 46.53L55.52 50.01L17.96 50.01C17.68 50.01 17.45 50.06 17.27 50.15C17.09 50.24 17 50.36 17 50.51L17 53.49C17 53.64 17.09 53.75 17.27 53.85C17.45 53.94 17.68 53.99 17.96 53.99L55.52 53.99L55.52 57.47C55.52 57.67 55.71 57.82 56.09 57.92C56.47 58 56.82 57.97 57.14 57.82L68.7 52.33C68.9 52.22 69 52.1 69 51.95C69 51.82 68.9 51.7 68.7 51.6L68.7 51.6Z"
                        />
                      </svg>
                    </div>
                    <div
                      data-hook-el="snap_top"
                      class="w-[30px] h-[30px] border rounded-sm border-black cursor-pointer"
                    >
                      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
                        <style>
                          tspan { white-space:pre }.shp0 { fill: #000000 }
                        </style>
                        <path class="shp0" d="M10 13L88 13L88 24L10 24L10 13Z" /><path
                          class="shp0"
                          d="M48.4 31.3L53.84 42.86C53.97 43.18 54 43.53 53.92 43.91C53.83 44.29 53.68 44.48 53.47 44.48L49.99 44.48L49.99 82.04C49.99 82.32 49.94 82.55 49.85 82.73C49.76 82.91 49.64 83 49.49 83L46.51 83C46.36 83 46.25 82.91 46.15 82.73C46.06 82.55 46.01 82.32 46.01 82.04L46.01 44.48L42.53 44.48C42.33 44.48 42.18 44.29 42.08 43.91C42 43.53 42.03 43.18 42.18 42.86L47.67 31.3C47.78 31.1 47.9 31 48.05 31C48.18 31 48.3 31.1 48.4 31.3L48.4 31.3Z"
                        />
                      </svg>
                    </div>
                    <div
                      data-hook-el="snap_bottom"
                      class="w-[30px] h-[30px] border rounded-sm border-black cursor-pointer"
                    >
                      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
                        <style>
                          tspan { white-space:pre }.shp0 { fill: #000000 }
                        </style>
                        <path class="shp0" d="M10 76L88 76L88 87L10 87L10 76Z" /><path
                          class="shp0"
                          d="M48.4 68.7L53.84 57.14C53.97 56.82 54 56.47 53.92 56.09C53.83 55.71 53.68 55.52 53.47 55.52L49.99 55.52L49.99 17.96C49.99 17.68 49.94 17.45 49.85 17.27C49.76 17.09 49.64 17 49.49 17L46.51 17C46.36 17 46.25 17.09 46.15 17.27C46.06 17.45 46.01 17.68 46.01 17.96L46.01 55.52L42.53 55.52C42.33 55.52 42.18 55.71 42.08 56.09C42 56.47 42.03 56.82 42.18 57.14L47.67 68.7C47.78 68.9 47.9 69 48.05 69C48.18 69 48.3 68.9 48.4 68.7L48.4 68.7Z"
                        />
                      </svg>
                    </div>
                    <div
                      data-hook-el="snap_x"
                      class="w-[30px] h-[30px] border rounded-sm border-black cursor-pointer"
                    >
                      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
                        <style>
                          tspan { white-space:pre }.shp0 { fill: #000000 }
                        </style>
                        <path class="shp0" d="M13 12L24 12L24 90L13 90L13 12Z" /><path
                          class="shp0"
                          d="M76 12L87 12L87 90L76 90L76 12Z"
                        /><path
                          class="shp0"
                          d="M68.6 51.16L63.17 46.36C62.9 46.12 62.58 46 62.21 46C61.85 46 61.53 46.12 61.26 46.36C60.99 46.59 60.86 46.88 60.86 47.2L60.86 49.6L39.14 49.6L39.14 47.2C39.14 46.88 39.01 46.59 38.74 46.36C38.47 46.12 38.15 46 37.79 46C37.42 46 37.1 46.12 36.83 46.36L31.4 51.16C31.13 51.39 31 51.68 31 52C31 52.33 31.13 52.61 31.4 52.84L36.83 57.64C37.1 57.88 37.42 58 37.79 58C38.15 58 38.47 57.88 38.74 57.64C39.01 57.41 39.14 57.13 39.14 56.8L39.14 54.4L60.86 54.4L60.86 56.8C60.86 57.13 60.99 57.41 61.26 57.64C61.53 57.88 61.85 58 62.21 58C62.58 58 62.9 57.88 63.17 57.64L68.6 52.84C68.87 52.61 69 52.33 69 52C69 51.68 68.87 51.39 68.6 51.16L68.6 51.16Z"
                        />
                      </svg>
                    </div>
                    <div
                      data-hook-el="snap_y"
                      class="w-[30px] h-[30px] border rounded-sm border-black cursor-pointer"
                    >
                      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
                        <style>
                          tspan { white-space:pre }.shp0 { fill: #000000 }
                        </style>
                        <path class="shp0" d="M10 13L88 13L88 24L10 24L10 13Z" /><path
                          class="shp0"
                          d="M10 76L88 76L88 87L10 87L10 76Z"
                        /><path
                          class="shp0"
                          d="M48.84 68.6L53.64 63.17C53.88 62.9 54 62.58 54 62.21C54 61.85 53.88 61.53 53.64 61.26C53.41 60.99 53.12 60.86 52.8 60.86L50.4 60.86L50.4 39.14L52.8 39.14C53.12 39.14 53.41 39.01 53.64 38.74C53.88 38.47 54 38.15 54 37.79C54 37.42 53.88 37.1 53.64 36.83L48.84 31.4C48.61 31.13 48.32 31 48 31C47.67 31 47.39 31.13 47.16 31.4L42.36 36.83C42.12 37.1 42 37.42 42 37.79C42 38.15 42.12 38.47 42.36 38.74C42.59 39.01 42.87 39.14 43.2 39.14L45.6 39.14L45.6 60.86L43.2 60.86C42.87 60.86 42.59 60.99 42.36 61.26C42.12 61.53 42 61.85 42 62.21C42 62.58 42.12 62.9 42.36 63.17L47.16 68.6C47.39 68.87 47.67 69 48 69C48.32 69 48.61 68.87 48.84 68.6L48.84 68.6Z"
                        />
                      </svg>
                    </div>
                    <div
                      data-hook-el="snap_center"
                      class="w-[30px] h-[30px] border rounded-sm border-black cursor-pointer"
                    >
                      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
                        <style>
                          tspan { white-space:pre }.shp0 { fill: #000000 }
                        </style>
                        <g>
                          <path
                            class="shp0"
                            d="M37.83 50.26L31.39 47.09C31.21 47.02 31.01 47 30.8 47.05C30.59 47.1 30.48 47.18 30.48 47.31L30.48 49.34L9.54 49.34C9.38 49.34 9.25 49.37 9.15 49.42C9.05 49.48 9 49.55 9 49.63L9 51.37C9 51.45 9.05 51.52 9.15 51.58C9.25 51.63 9.38 51.66 9.54 51.66L30.48 51.66L30.48 53.69C30.48 53.81 30.59 53.9 30.8 53.95C31.01 54 31.21 53.98 31.39 53.9L37.83 50.69C37.94 50.63 38 50.56 38 50.47C38 50.39 37.94 50.32 37.83 50.26L37.83 50.26Z"
                          /><path
                            class="shp0"
                            d="M63.17 50.26L69.61 47.09C69.79 47.02 69.99 47 70.2 47.05C70.41 47.1 70.52 47.18 70.52 47.31L70.52 49.34L91.46 49.34C91.62 49.34 91.75 49.37 91.85 49.42C91.95 49.48 92 49.55 92 49.63L92 51.37C92 51.45 91.95 51.52 91.85 51.58C91.75 51.63 91.62 51.66 91.46 51.66L70.52 51.66L70.52 53.69C70.52 53.81 70.41 53.9 70.2 53.95C69.99 54 69.79 53.98 69.61 53.9L63.17 50.69C63.06 50.63 63 50.56 63 50.47C63 50.39 63.06 50.32 63.17 50.26L63.17 50.26Z"
                          />
                        </g>
                        <g>
                          <path
                            class="shp0"
                            d="M49.74 37.83L52.91 31.39C52.98 31.21 53 31.01 52.95 30.8C52.9 30.59 52.82 30.48 52.69 30.48L50.66 30.48L50.66 9.54C50.66 9.38 50.63 9.25 50.58 9.15C50.52 9.05 50.45 9 50.37 9L48.63 9C48.55 9 48.48 9.05 48.42 9.15C48.37 9.25 48.34 9.38 48.34 9.54L48.34 30.48L46.31 30.48C46.19 30.48 46.1 30.59 46.05 30.8C46 31.01 46.02 31.21 46.1 31.39L49.31 37.83C49.37 37.94 49.44 38 49.53 38C49.61 38 49.68 37.94 49.74 37.83L49.74 37.83Z"
                          /><path
                            class="shp0"
                            d="M49.74 63.17L52.91 69.61C52.98 69.79 53 69.99 52.95 70.2C52.9 70.41 52.82 70.52 52.69 70.52L50.66 70.52L50.66 91.46C50.66 91.62 50.63 91.75 50.58 91.85C50.52 91.95 50.45 92 50.37 92L48.63 92C48.55 92 48.48 91.95 48.42 91.85C48.37 91.75 48.34 91.62 48.34 91.46L48.34 70.52L46.31 70.52C46.19 70.52 46.1 70.41 46.05 70.2C46 69.99 46.02 69.79 46.1 69.61L49.31 63.17C49.37 63.06 49.44 63 49.53 63C49.61 63 49.68 63.06 49.74 63.17L49.74 63.17Z"
                          />
                        </g>
                      </svg>
                    </div>
                    <div class="text-sm">
                      <input data-hook-el="allow_upscale" type="checkbox" /> Allow Upscale
                    </div>
                    <div class="flex-grow"></div>
                    <div>
                      <.button type="button" data-hook-el="done">Crop</.button>
                    </div>
                  </div>
                  <div data-hook-el="cropper_holder"></div>
                  <div data-hook-el="status_small">
                    <.alert with_icon color="danger">
                      The cropping area is smaller than the required resolution, so the image may look blurry.
                      Select a larger cropping area or try a higher quality source image of at least <%= @min_width %> x <%= @min_height %>.
                    </.alert>
                  </div>
                  <div data-hook-el="status_padded">
                    <.alert with_icon color="warning">
                      The cropping area includes padding to fill the required dimensions.  Adjust the cropping
                      area or try a source image of at least <%= @min_width %> x <%= @min_height %>.
                    </.alert>
                  </div>
                  <div data-hook-el="status_ok">
                    <.alert with_icon color="success">
                      This cropping area will work.
                    </.alert>
                  </div>
                </div>
              <% end %>
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
              src={Nox.Repo.GCSAsset.public_url(@current)}
              class="border-dashed border max-w-full block"
              style={"max-height:#{@min_height}px;"}
            />
          <% true -> %>
        <% end %>
      </section>
    </div>
    """
  end

  defmodule Helpers do
    alias Phoenix.LiveView.{UploadConfig, Upload}

    def validate_cropped_uploads(socket, name) when is_atom(name) do
      %UploadConfig{} = conf = Map.fetch!(socket.assigns.uploads, name)

      conf.entries
      |> Enum.reduce(socket, fn entry, acc ->
        if String.starts_with?(entry.client_name, "(cropped)") do
          acc
        else
          Upload.put_upload_error(acc, name, entry.ref, :not_cropped)
        end
      end)
    end

    def validate_cropped_uploads(socket, names) when is_list(names) do
      names
      |> Enum.reduce(socket, fn name, acc ->
        acc
        |> validate_cropped_uploads(name)
      end)
    end
  end
end
