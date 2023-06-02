defmodule Nox.Repo.MuxAsset do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  @primary_key false
  embedded_schema do
    field :id, :string
    field :aspect_ratio, :string
    field :created_at, :integer
    field :duration, :float
    field :master_access, :string
    field :max_stored_frame_rate, :float
    field :max_stored_resolution, :string
    field :mp4_support, :string
    field :passthrough, :string
    field :playback_ids, {:array, :map}
    field :status, :string
    field :tracks, {:array, :map}
    field :upload_id, :string
  end

  def changeset(scope, attrs) do
    scope
    |> cast(attrs, __MODULE__.__schema__(:fields))
  end

  def playback_url(%__MODULE__{
        status: "ready",
        playback_ids: [%{"id" => id, "policy" => "public"} | _]
      }) do
    "https://stream.mux.com/#{id}.m3u8"
  end

  def playback_url(_), do: nil

  def thumbnail_url(
        %__MODULE__{status: "ready", playback_ids: [%{"id" => id, "policy" => "public"} | _]},
        params
      ) do
    [
      "https://image.mux.com/#{id}/thumbnail.jpg",
      URI.encode_query(params)
    ]
    |> Enum.filter(fn x -> x && x != "" end)
    |> Enum.join("?")
  end

  def thumbnail_url(_, _), do: nil

  def cast_attachments(%{valid?: true} = changeset, attrs, fields) do
    scope = changeset.data

    origs =
      fields
      |> Enum.map(fn f -> {f, Map.get(scope, f)} end)
      |> Map.new()

    news =
      fields
      |> Enum.map(fn f ->
        case Map.get(attrs, "#{f}") do
          %{} = v ->
            {f, v}

          :delete ->
            {f, nil}

          _ ->
            nil
        end
      end)
      |> Enum.filter(& &1)
      |> Map.new()

    changeset =
      news
      |> Enum.reduce(changeset, fn {f, v}, acc ->
        case Map.get(origs, f) do
          %{id: id} ->
            Mux.Video.Assets.delete(Mux.client(), id)

          _ ->
            nil
        end

        if v == nil do
          acc
          |> Ecto.Changeset.put_embed(f, nil)
        else
          a =
            %__MODULE__{}
            |> __MODULE__.changeset(v)

          acc
          |> Ecto.Changeset.put_embed(f, a)
        end
      end)

    changeset
  end

  def cast_attachments(changeset, _attrs, _fields) do
    changeset
  end

  def delete_attachment(scope, field) do
    case Map.get(scope, field) do
      %{id: id} ->
        Mux.Video.Assets.delete(Mux.client(), id)

      _ ->
        nil
    end
  end

  def consume_uploaded_entries_to_params(socket, params, opts) do
    name = Keyword.fetch!(opts, :name)

    params =
      if Map.get(params, "#{name}_delete") == "DELETE" do
        params
        |> Map.delete("#{name}_delete")
        |> Map.put(Atom.to_string(name), :delete)
      else
        params
      end

    assets =
      Phoenix.LiveView.Upload.consume_uploaded_entries(socket, name, fn %{upload_id: upload_id},
                                                                        _entry ->
        {:ok, %{"asset_id" => asset_id}, _} = Mux.Video.Uploads.get(Mux.client(), upload_id)
        {:ok, asset, _} = Mux.Video.Assets.get(Mux.client(), asset_id)

        {:ok, asset}
      end)

    params =
      case assets do
        [%{"id" => _id} = asset] ->
          params
          |> Map.put(Atom.to_string(name), asset)

        _ ->
          params
      end

    {socket, params}
  end

  def presign_upload(socket, passthrough_data) do
    params = %{
      "new_asset_settings" => %{
        "playback_policy" => ["public"],
        "passthrough" => encode_passthrough(passthrough_data)
      },
      "cors_origin" => NoxWeb.Endpoint.url()
    }

    {:ok, %{"url" => url, "id" => upload_id}, _} = Mux.Video.Uploads.create(Mux.client(), params)

    {:ok, %{uploader: "UpChunk", entrypoint: url, upload_id: upload_id}, socket}
  end

  def decode_passthrough("enc:" <> str) do
    str
    |> Base.decode64!()
    |> :erlang.binary_to_term()
  end

  def encode_passthrough(term) do
    str =
      :erlang.term_to_binary(term)
      |> Base.encode64()

    "enc:" <> str
  end

  def update!(schema, field_name, %{"id" => id} = data) do
    res =
      from(x in schema, where: fragment("?->>'id' = ?", field(x, ^field_name), ^id), limit: 1)
      |> Nox.Repo.one!()
      |> Ecto.Changeset.change()
      |> Ecto.Changeset.put_embed(field_name, __MODULE__.changeset(%__MODULE__{}, data))
      |> Nox.Repo.update!()

    # @todo implement notify_updated functions
    if function_exported?(schema, :notify_updated, 1) do
      apply(schema, :notify_updated, [field_name])
    end

    res
  end

  def temporary_master_access!(%__MODULE__{id: id}) do
    Mux.Video.Assets.update_master_access(Mux.client(), id, %{"master_access" => "temporary"})
  end

  # def update_asset_mp4_support(%__MODULE__{id: id}, mp4_support \\ "standard") do
  #   Mux.Video.Assets.update_mp4_support(Mux.client(), id, %{"mp4_support" => mp4_support})
  # end

  def get_asset(%__MODULE__{id: id}) do
    {:ok, asset, _} = Mux.Video.Assets.get(Mux.client(), id)
    asset
  end
end
