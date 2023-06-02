defmodule Nox.Kickoff do
  require Logger

  def child_spec(_opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []},
      type: :worker,
      restart: :temporary,
      shutdown: 500
    }
  end

  def start_link() do
    kickoff_cleanup_binarykv_workers()

    :ignore
  end

  def kickoff_cleanup_binarykv_workers() do
    Nox.Workers.CleanupBinarykv.new(%{}, schedule_in: 1)
    |> Oban.insert()
  end
end
