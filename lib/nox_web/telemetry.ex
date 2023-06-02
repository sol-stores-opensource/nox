defmodule NoxWeb.Telemetry do
  use Supervisor
  import Telemetry.Metrics

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(_arg) do
    children = [
      # Telemetry poller will execute the given period measurements
      # every 10_000ms. Learn more here: https://hexdocs.pm/telemetry_metrics
      {:telemetry_poller, measurements: periodic_measurements(), period: 10_000}
      # Add reporters as children of your supervision tree.
      # {Telemetry.Metrics.ConsoleReporter, metrics: metrics()}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def metrics do
    [
      # Phoenix Metrics
      summary("phoenix.endpoint.stop.duration",
        unit: {:native, :millisecond}
      ),
      summary("phoenix.router_dispatch.stop.duration",
        tags: [:route],
        unit: {:native, :millisecond}
      ),

      # Database Metrics
      summary("nox.repo.query.total_time",
        unit: {:native, :millisecond},
        description: "The sum of the other measurements"
      ),
      summary("nox.repo.query.decode_time",
        unit: {:native, :millisecond},
        description: "The time spent decoding the data received from the database"
      ),
      summary("nox.repo.query.query_time",
        unit: {:native, :millisecond},
        description: "The time spent executing the query"
      ),
      summary("nox.repo.query.queue_time",
        unit: {:native, :millisecond},
        description: "The time spent waiting for a database connection"
      ),
      summary("nox.repo.query.idle_time",
        unit: {:native, :millisecond},
        description:
          "The time the connection spent waiting before being checked out for the query"
      ),

      # VM Metrics
      summary("vm.memory.total", unit: {:byte, :kilobyte}),
      summary("vm.total_run_queue_lengths.total"),
      summary("vm.total_run_queue_lengths.cpu"),
      summary("vm.total_run_queue_lengths.io"),

      # Nox Metrics
      last_value("nox.connections.total"),
      last_value("nox.db_connections.max_conn"),
      last_value("nox.db_connections.used"),
      last_value("nox.db_connections.res_for_super"),
      last_value("nox.db_connections.res_for_normal")
    ]
  end

  defp periodic_measurements do
    [
      # A module, function and arguments to be invoked periodically.
      # This function must call :telemetry.execute/3 and a metric must be added above.
      # {NoxWeb, :count_users, []}
      {__MODULE__, :count_connections, []},
      {__MODULE__, :count_db_connections, []}
    ]
  end

  def count_connections() do
    :telemetry.execute([:nox, :connections], %{total: Nox.Recon.safe_all_tcp_inet()}, %{})
  end

  def count_db_connections() do
    was_log_enabled = Nox.DevDisableLog.disable_in_dev()

    sql = """
    select max_conn,used,res_for_super,max_conn-used-res_for_super res_for_normal
    from
      (select count(*) used from pg_stat_activity) t1,
      (select setting::int res_for_super from pg_settings where name=$$superuser_reserved_connections$$) t2,
      (select setting::int max_conn from pg_settings where name=$$max_connections$$) t3
    """

    case Ecto.Adapters.SQL.query!(Nox.Repo, sql, []) do
      %{rows: [[max_conn, used, res_for_super, res_for_normal]]} ->
        :telemetry.execute([:nox, :db_connections], %{max_conn: max_conn}, %{})
        :telemetry.execute([:nox, :db_connections], %{used: used}, %{})
        :telemetry.execute([:nox, :db_connections], %{res_for_super: res_for_super}, %{})
        :telemetry.execute([:nox, :db_connections], %{res_for_normal: res_for_normal}, %{})

      _ ->
        :telemetry.execute([:nox, :db_connections], %{max_conn: 0}, %{})
        :telemetry.execute([:nox, :db_connections], %{used: 0}, %{})
        :telemetry.execute([:nox, :db_connections], %{res_for_super: 0}, %{})
        :telemetry.execute([:nox, :db_connections], %{res_for_normal: 0}, %{})
    end

    Nox.DevDisableLog.reenable_in_dev(was_log_enabled)

    :ok
  end
end
