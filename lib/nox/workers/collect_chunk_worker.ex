defmodule Nox.Workers.CollectChunkWorker do
  require Logger
  use Oban.Pro.Workers.Chunk, queue: :collect, size: 1000, timeout: 10000

  # a valid key is required to insert data into the collect database.
  # hardcoding them for now.
  @nox_key "nox-2f2844c9-d48d-4a51-a45b-12bbc976f401"

  @allow_keys [
    @nox_key
  ]

  @impl true
  def process([_ | _] = jobs) do
    collect_dataset = Application.get_env(:nox, :nox_dataset)
    collect_table = Application.get_env(:nox, :collect_table)

    handle_jobs(collect_dataset, collect_table, jobs)
  end

  def handle_jobs(collect_dataset, collect_table, jobs)
      when is_binary(collect_dataset) and is_binary(collect_table) do
    rows =
      jobs
      |> Enum.map(fn %{args: %{"encoded" => encoded}} ->
        encoded
        |> Base.decode64!()
        |> :erlang.binary_to_term()
      end)

    result = Nox.BigQuery.insert_all(collect_dataset, collect_table, rows)

    if result do
      :ok
    else
      # will trigger an entire retry
      {:error, "insert_all failed", jobs}
    end
  end

  def handle_jobs(collect_dataset, collect_table, _jobs) do
    Logger.warn(
      "#{__MODULE__} SKIP.  collect_dataset=#{inspect(collect_dataset)} collect_table=#{inspect(collect_table)}"
    )

    :ok
  end

  # for internal use
  def nox_add(payload) when is_map(payload) and not is_struct(payload) do
    payload
    |> Map.put("key", @nox_key)
    |> add()
  end

  def add(%{"key" => key} = payload) when key in @allow_keys and not is_struct(payload) do
    payload =
      payload
      |> Map.put_new("id", Ecto.UUID.generate())
      |> Map.put_new("ts", Timex.now())

    encoded =
      :erlang.term_to_binary(payload)
      |> Base.encode64()

    __MODULE__.new(%{"encoded" => encoded})
    |> Oban.insert()
  end

  def add(payload) do
    Logger.warn("#{__MODULE__} CANTADD.  payload=#{inspect(payload)}")

    :error
  end
end
