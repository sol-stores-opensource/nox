defmodule Nox.Workers.CleanupBinarykv do
  require Logger

  alias Nox.Repo

  use Oban.Pro.Worker,
    queue: :default,
    priority: 1,
    max_attempts: 5,
    unique: [
      period: :infinity,
      states: [:available, :scheduled, :executing, :retryable]
    ]

  import Ecto.Query

  @impl Oban.Pro.Worker
  def process(_) do
    was_log_enabled = Nox.DevDisableLog.disable_in_dev()

    case from(x in Repo.BinaryKv,
           where: not is_nil(x.exp) and x.exp < fragment("now()")
         )
         |> Repo.delete_all() do
      {n, _} when n > 0 ->
        Logger.info("#{__MODULE__} deleted #{n} expired KVs")

      _ ->
        nil
    end

    Nox.DevDisableLog.reenable_in_dev(was_log_enabled)

    {:snooze, 30}
  end
end
