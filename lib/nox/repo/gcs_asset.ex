defmodule Nox.Repo.GCSAsset do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :bucket, :string
    field :contentType, :string
    field :etag, :string
    field :generation, :string
    field :id, :string
    field :kind, :string
    field :md5Hash, :string
    field :mediaLink, :string
    field :name, :string
    field :selfLink, :string
    field :size, :string
    field :updated, :utc_datetime_usec
  end

  def changeset(scope, attrs) do
    scope
    |> cast(attrs, __MODULE__.__schema__(:fields))
  end

  def public_url(%__MODULE__{} = asset) do
    "https://storage.googleapis.com/#{asset.bucket}/#{asset.name}"
  end

  def public_url(_), do: nil

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
        orig = Map.get(origs, f)

        if orig do
          conn = apply(scope.__struct__(), String.to_atom("#{f}_conn"), [])
          bucket = apply(scope.__struct__(), String.to_atom("#{f}_bucket"), [])

          Nox.Google.Storage.delete_file(
            conn,
            bucket,
            orig.name
          )
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
      %{name: name, bucket: bucket} ->
        conn = apply(scope.__struct__(), String.to_atom("#{field}_conn"), [])

        Nox.Google.Storage.delete_file(
          conn,
          bucket,
          name
        )

      _ ->
        nil
    end
  end

  def presign_upload(socket, path, {scope, f}) do
    conn = apply(scope, String.to_atom("#{f}_conn"), [])

    %{pre: pre} = conn

    pre =
      pre ++
        [{Tesla.Middleware.Headers, :call, [[{"origin", NoxWeb.Endpoint.url()}]]}]

    conn =
      conn
      |> Map.put(:pre, pre)

    bucket = apply(scope, String.to_atom("#{f}_bucket"), [])

    {:ok, res} =
      Nox.Google.Storage.upload_resumable(
        conn,
        bucket,
        name: path,
        predefinedAcl: "publicRead"
      )

    url = Tesla.get_header(res, "location")

    {:ok, %{uploader: "UpChunk", entrypoint: url, upload_id: path}, socket}
  end

  if Application.compile_env!(:nox, :env) == :test do
    def default_conn() do
      nil
    end

    def default_bucket() do
      nil
    end
  else
    def default_conn() do
      goth = Goth.fetch!(Nox.Goth)

      GoogleApi.Storage.V1.Connection.new(goth.token)
    end

    def default_bucket() do
      Application.fetch_env!(:nox, :uploads_bucket)
    end
  end

  def consume_uploaded_entries_to_params(socket, params, opts) do
    name = Keyword.fetch!(opts, :name)
    scope = Keyword.fetch!(opts, :scope)

    params =
      if Map.get(params, "#{name}_delete") == "DELETE" do
        params
        |> Map.delete("#{name}_delete")
        |> Map.put(Atom.to_string(name), :delete)
      else
        params
      end

    files =
      Phoenix.LiveView.Upload.consume_uploaded_entries(socket, name, fn %{upload_id: upload_id},
                                                                        _entry ->
        conn = apply(scope, String.to_atom("#{name}_conn"), [])
        bucket = apply(scope, String.to_atom("#{name}_bucket"), [])

        {:ok, %GoogleApi.Storage.V1.Model.Object{} = obj} =
          Nox.Google.Storage.get_file_info(conn, bucket, upload_id)

        {:ok, Map.from_struct(obj)}
      end)

    params =
      case files do
        [%{} = obj] ->
          params
          |> Map.put(Atom.to_string(name), obj)

        _ ->
          params
      end

    {socket, params}
  end
end
