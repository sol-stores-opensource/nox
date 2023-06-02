defmodule Nox.BigQuery do
  require Logger

  # NOTES
  # unhandled: BYTES, BIGNUMERIC, DATETIME, INTERVAL

  def sync_query(sql) do
    {:ok, token} = Goth.fetch(Nox.Goth)
    conn = GoogleApi.BigQuery.V2.Connection.new(token.token)
    {_, %{"project_id" => project_id}, _} = Application.get_env(:nox, :goth_source)

    # Make the API request
    {:ok, response} =
      GoogleApi.BigQuery.V2.Api.Jobs.bigquery_jobs_query(
        conn,
        project_id,
        body: %GoogleApi.BigQuery.V2.Model.QueryRequest{query: sql}
      )

    response.rows
    |> Enum.each(fn row ->
      row.f
      |> Enum.with_index()
      |> Enum.each(fn {cell, i} ->
        IO.puts("#{Enum.at(response.schema.fields, i).name}: #{cell.v}")
      end)
    end)
  end

  def insert_all(_dataset_id, _table_id, []), do: true

  def insert_all(dataset_id, table_id, rows) do
    {:ok, token} = Goth.fetch(Nox.Goth)
    conn = GoogleApi.BigQuery.V2.Connection.new(token.token)
    {_, %{"project_id" => project_id}, _} = Application.get_env(:nox, :goth_source)

    bq_rows = data_to_bq_struct(rows)
    len = length(bq_rows)

    result =
      GoogleApi.BigQuery.V2.Api.Tabledata.bigquery_tabledata_insert_all(
        conn,
        project_id,
        dataset_id,
        table_id,
        body: %GoogleApi.BigQuery.V2.Model.TableDataInsertAllRequest{
          ignoreUnknownValues: false,
          skipInvalidRows: false,
          kind: "bigquery#tableDataInsertAllRequest",
          rows: bq_rows
        }
      )

    case result do
      {:ok, %{insertErrors: nil}} ->
        Logger.info("#{__MODULE__} INSERTED #{len}")
        true

      result ->
        Logger.warn("#{__MODULE__} INSERT ERRORS #{inspect(result)}")
        ensure_dataset(dataset_id)
        table = ensure_table(dataset_id, table_id)
        needed_schema = data_to_schema(rows)
        new_schema = merge_schema(table.schema, needed_schema)

        if new_schema != table.schema do
          pres = patch_schema(dataset_id, table_id, new_schema)
          Logger.warn("#{__MODULE__} PATCH_SCHEMA #{inspect(pres)}")
        end

        case GoogleApi.BigQuery.V2.Api.Tabledata.bigquery_tabledata_insert_all(
               conn,
               project_id,
               dataset_id,
               table_id,
               body: %GoogleApi.BigQuery.V2.Model.TableDataInsertAllRequest{
                 ignoreUnknownValues: false,
                 skipInvalidRows: false,
                 kind: "bigquery#tableDataInsertAllRequest",
                 rows: bq_rows
               }
             ) do
          {:ok, %{insertErrors: nil}} ->
            Logger.info("#{__MODULE__} INSERTED AFTER RETRY #{len}")
            true

          result ->
            Logger.warn("#{__MODULE__} INSERT ERRORS AFTER RETRY #{inspect(result)}")
            false
        end
    end
  end

  def ensure_dataset(dataset_id) do
    {:ok, token} = Goth.fetch(Nox.Goth)
    conn = GoogleApi.BigQuery.V2.Connection.new(token.token)
    {_, %{"project_id" => project_id}, _} = Application.get_env(:nox, :goth_source)

    case GoogleApi.BigQuery.V2.Api.Datasets.bigquery_datasets_get(conn, project_id, dataset_id) do
      {:error, _} ->
        {:ok, dataset} =
          GoogleApi.BigQuery.V2.Api.Datasets.bigquery_datasets_insert(conn, project_id,
            body: %GoogleApi.BigQuery.V2.Model.Dataset{
              datasetReference: %{datasetId: dataset_id, projectId: project_id},
              location: "US"
            }
          )

        dataset

      {:ok, dataset} ->
        dataset
    end
  end

  def get_table(dataset_id, table_id) do
    {:ok, token} = Goth.fetch(Nox.Goth)
    conn = GoogleApi.BigQuery.V2.Connection.new(token.token)
    {_, %{"project_id" => project_id}, _} = Application.get_env(:nox, :goth_source)

    case GoogleApi.BigQuery.V2.Api.Tables.bigquery_tables_get(
           conn,
           project_id,
           dataset_id,
           table_id
         ) do
      {:error, _} ->
        nil

      {:ok, table} ->
        table
    end
  end

  def ensure_table(dataset_id, table_id) do
    table = get_table(dataset_id, table_id)

    if table do
      table
    else
      {:ok, token} = Goth.fetch(Nox.Goth)
      conn = GoogleApi.BigQuery.V2.Connection.new(token.token)
      {_, %{"project_id" => project_id}, _} = Application.get_env(:nox, :goth_source)

      {:ok, table} =
        GoogleApi.BigQuery.V2.Api.Tables.bigquery_tables_insert(conn, project_id, dataset_id,
          body: %GoogleApi.BigQuery.V2.Model.Table{
            schema: nil,
            tableReference: %{datasetId: dataset_id, projectId: project_id, tableId: table_id}
          }
        )

      table
    end
  end

  def patch_schema(dataset_id, table_id, schema) do
    {:ok, token} = Goth.fetch(Nox.Goth)
    conn = GoogleApi.BigQuery.V2.Connection.new(token.token)
    {_, %{"project_id" => project_id}, _} = Application.get_env(:nox, :goth_source)

    GoogleApi.BigQuery.V2.Api.Tables.bigquery_tables_patch(conn, project_id, dataset_id, table_id,
      body: %GoogleApi.BigQuery.V2.Model.Table{
        schema: schema,
        tableReference: %{datasetId: dataset_id, projectId: project_id, tableId: table_id}
      }
    )
  end

  ### data_to_bq_struct

  def data_to_bq_struct(rows) when is_list(rows) do
    rows
    |> Enum.map(&data_to_bq_struct/1)
    |> Enum.filter(& &1)
  end

  def data_to_bq_struct(row) when is_map(row) and not is_struct(row) do
    bq_json =
      row
      |> Enum.map(&data_to_bq_struct/1)
      |> Enum.filter(& &1)
      |> Map.new()

    if bq_json == %{} do
      nil
    else
      %GoogleApi.BigQuery.V2.Model.TableDataInsertAllRequestRows{
        insertId: Map.get(row, :id) || Map.get(row, "id"),
        json: bq_json
      }
    end
  end

  def data_to_bq_struct({_k, nil}) do
    nil
  end

  def data_to_bq_struct({k, v}) when is_map(v) and not is_struct(v) do
    new_v =
      v
      |> Enum.map(&data_to_bq_struct/1)
      |> Enum.filter(& &1)
      |> Map.new()

    if new_v == %{} do
      nil
    else
      {"#{k}_RECORD", new_v}
    end
  end

  def data_to_bq_struct({k, v}) when is_binary(v) do
    {"#{k}_STRING", v}
  end

  def data_to_bq_struct({k, v}) when is_integer(v) do
    {"#{k}_INTEGER", v}
  end

  def data_to_bq_struct({k, v}) when is_float(v) do
    {"#{k}_FLOAT", v}
  end

  def data_to_bq_struct({k, v}) when is_boolean(v) do
    {"#{k}_BOOLEAN", v}
  end

  def data_to_bq_struct({k, %Decimal{} = v}) do
    {"#{k}_NUMERIC", v}
  end

  def data_to_bq_struct({k, %DateTime{} = v}) do
    {"#{k}_TIMESTAMP", DateTime.to_iso8601(v)}
  end

  def data_to_bq_struct({k, %Date{} = v}) do
    {"#{k}_DATE", Date.to_iso8601(v)}
  end

  def data_to_bq_struct({k, %Time{} = v}) do
    {"#{k}_TIME", Time.to_iso8601(v)}
  end

  ### END data_to_bq_struct

  ### data_to_schema

  def data_to_schema(v) when is_list(v) do
    v
    |> Enum.map(&data_to_schema/1)
    |> Enum.filter(& &1)
    |> merge_schema()
  end

  def data_to_schema(v) when is_map(v) and not is_struct(v) do
    %GoogleApi.BigQuery.V2.Model.TableSchema{
      fields:
        Enum.map(v, &data_to_schema/1)
        |> Enum.filter(& &1)
    }
  end

  def data_to_schema({_k, nil}) do
    nil
  end

  def data_to_schema({k, v}) when is_map(v) and not is_struct(v) do
    fields = Enum.map(v, &data_to_schema/1)

    if length(fields) == 0 do
      nil
    else
      %GoogleApi.BigQuery.V2.Model.TableFieldSchema{
        name: "#{k}_RECORD",
        type: "RECORD",
        mode: "NULLABLE",
        fields: fields
      }
    end
  end

  def data_to_schema({k, v}) when is_binary(v) do
    %GoogleApi.BigQuery.V2.Model.TableFieldSchema{
      name: "#{k}_STRING",
      type: "STRING",
      mode: "NULLABLE"
    }
  end

  def data_to_schema({k, v}) when is_integer(v) do
    %GoogleApi.BigQuery.V2.Model.TableFieldSchema{
      name: "#{k}_INTEGER",
      type: "INTEGER",
      mode: "NULLABLE"
    }
  end

  def data_to_schema({k, v}) when is_float(v) do
    %GoogleApi.BigQuery.V2.Model.TableFieldSchema{
      name: "#{k}_FLOAT",
      type: "FLOAT",
      mode: "NULLABLE"
    }
  end

  def data_to_schema({k, v}) when is_boolean(v) do
    %GoogleApi.BigQuery.V2.Model.TableFieldSchema{
      name: "#{k}_BOOLEAN",
      type: "BOOLEAN",
      mode: "NULLABLE"
    }
  end

  def data_to_schema({k, %Decimal{}}) do
    %GoogleApi.BigQuery.V2.Model.TableFieldSchema{
      name: "#{k}_NUMERIC",
      type: "NUMERIC",
      mode: "NULLABLE"
    }
  end

  def data_to_schema({k, %DateTime{}}) do
    %GoogleApi.BigQuery.V2.Model.TableFieldSchema{
      name: "#{k}_TIMESTAMP",
      type: "TIMESTAMP",
      mode: "NULLABLE"
    }
  end

  def data_to_schema({k, %Date{}}) do
    %GoogleApi.BigQuery.V2.Model.TableFieldSchema{
      name: "#{k}_DATE",
      type: "DATE",
      mode: "NULLABLE"
    }
  end

  def data_to_schema({k, %Time{}}) do
    %GoogleApi.BigQuery.V2.Model.TableFieldSchema{
      name: "#{k}_TIME",
      type: "TIME",
      mode: "NULLABLE"
    }
  end

  ### END data_to_schema

  ### merge_schema

  def merge_schema([
        %GoogleApi.BigQuery.V2.Model.TableSchema{} = h,
        %GoogleApi.BigQuery.V2.Model.TableSchema{} = t
      ]) do
    merge_schema(h, t)
  end

  def merge_schema([
        %GoogleApi.BigQuery.V2.Model.TableSchema{} = h
        | [%GoogleApi.BigQuery.V2.Model.TableSchema{} = s | t]
      ]) do
    h = merge_schema(h, s)
    merge_schema([h | t])
  end

  def merge_schema([%GoogleApi.BigQuery.V2.Model.TableSchema{} = h]) do
    h
  end

  # def merge_schema(other) do
  #   IO.inspect(other, label: "merge_schema/1")
  #   raise "oops"
  # end

  def merge_schema(
        nil,
        %GoogleApi.BigQuery.V2.Model.TableSchema{} = schema
      ) do
    schema
  end

  def merge_schema(
        %GoogleApi.BigQuery.V2.Model.TableSchema{fields: original_fields} = original,
        %GoogleApi.BigQuery.V2.Model.TableSchema{fields: needed_fields}
      ) do
    %{original | fields: merge_schema(original_fields, needed_fields)}
  end

  def merge_schema(nil, needed_fields) when is_list(needed_fields) do
    needed_fields
  end

  def merge_schema(
        original_fields,
        needed_fields
      )
      when is_list(original_fields) and is_list(needed_fields) do
    original_names =
      original_fields
      |> Enum.map(fn %{name: name} -> name end)
      |> MapSet.new()

    # get list of new fields
    new_fields =
      needed_fields
      |> Enum.filter(fn
        %{name: name} -> !MapSet.member?(original_names, name)
        _ -> false
      end)

    # combine orig + new fields
    merged_fields = original_fields ++ new_fields

    # map through all. for records, recurse merge fields
    merged_fields
    |> Enum.map(fn
      %GoogleApi.BigQuery.V2.Model.TableFieldSchema{name: name, type: "RECORD"} = field ->
        needed_record_fields =
          Enum.find(needed_fields, %{}, fn x -> x.name == name end)
          |> Map.get(:fields, [])

        %{field | fields: merge_schema(field.fields || [], needed_record_fields)}

      field ->
        field
    end)
  end

  # def merge_schema(other, other2) do
  #   IO.inspect([other, other2], label: "merge_schema/2")
  #   raise "oops"
  # end

  ### END merge_schema
end
