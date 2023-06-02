defmodule Nox.Google.Storage do
  @moduledoc """
  Basic Google Cloud Storage list/create/delete operations
  """

  require Logger

  def upload_resumable(conn, bucket, optional_params \\ [], opts \\ []) do
    GoogleApi.Storage.V1.Api.Objects.storage_objects_insert_resumable(
      conn,
      bucket,
      "resumable",
      optional_params,
      opts
    )
  end

  def upload_object(
        conn,
        bucket,
        %GoogleApi.Storage.V1.Model.Object{} = object,
        path,
        optional_params \\ []
      ) do
    GoogleApi.Storage.V1.Api.Objects.storage_objects_insert_simple(
      conn,
      bucket,
      "multipart",
      object,
      path,
      optional_params
    )
  end

  def upload_file(conn, bucket, mime, name, path) do
    GoogleApi.Storage.V1.Api.Objects.storage_objects_insert_simple(
      conn,
      bucket,
      "multipart",
      %GoogleApi.Storage.V1.Model.Object{name: name, contentType: mime},
      path
    )
  end

  def upload_iodata(conn, bucket, mime, name, iodata, optional_params \\ [], opts \\ []) do
    GoogleApi.Storage.V1.Api.Objects.storage_objects_insert_iodata(
      conn,
      bucket,
      "multipart",
      %GoogleApi.Storage.V1.Model.Object{name: name, contentType: mime},
      iodata,
      optional_params,
      opts
    )
  end

  def get_file_info(conn, bucket, name) do
    GoogleApi.Storage.V1.Api.Objects.storage_objects_get(
      conn,
      bucket,
      name
    )
  end

  def get_file(conn, bucket, name) do
    case GoogleApi.Storage.V1.Api.Objects.storage_objects_get(
           conn,
           bucket,
           name,
           [alt: "media"],
           decode: false
         ) do
      {:ok,
       %Tesla.Env{
         body: body,
         status: status
       } = tesla}
      when is_binary(body) and status >= 200 and status < 300 ->
        {:ok, body, tesla}

      other ->
        {:error, other}
    end
  end

  def delete_file(conn, bucket, name) do
    Logger.info("#{__MODULE__}: deleting file #{inspect(bucket)} #{inspect(name)}")

    GoogleApi.Storage.V1.Api.Objects.storage_objects_delete(
      conn,
      bucket,
      name
    )
  end
end
