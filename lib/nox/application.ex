defmodule Nox.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  require Logger
  use Application

  @impl true
  def start(_type, _args) do
    topologies = Application.get_env(:libcluster, :topologies) || []

    children =
      [
        # cluster
        {Cluster.Supervisor, [topologies, [name: Nox.ClusterSupervisor]]},
        # Start the Ecto repository
        Nox.Repo,
        # Vault
        Nox.Vault,
        # Start the Telemetry supervisor
        NoxWeb.Telemetry,
        # Start the PubSub system
        {Phoenix.PubSub, name: Nox.PubSub},
        # Presence
        Nox.Presence,
        # Start the Endpoint (http/https)
        NoxWeb.Endpoint,
        # General TaskSupervisor
        {Task.Supervisor, name: Nox.TaskSupervisor},
        # Goth
        get_goth(),
        # Oban
        {Oban, oban_config()},
        # Start a worker by calling: Nox.Worker.start_link(arg)
        # {Nox.Worker, arg}
        Nox.Kickoff
      ]
      |> Enum.filter(& &1)

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Nox.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    NoxWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp oban_config() do
    opts = Application.get_env(:nox, Oban)

    # Prevent cron jobs from an iex console.
    if Application.get_env(:nox, :disable_oban) || (Code.ensure_loaded?(IEx) and IEx.started?()) do
      Logger.warn("NOTE: Oban.Pro.Plugins.DynamicCron DISABLED in IEx session")

      plugins =
        Keyword.get(opts, :plugins, [])
        |> Enum.filter(fn
          {Oban.Pro.Plugins.DynamicCron, _} -> false
          _ -> true
        end)

      opts
      |> Keyword.put(:plugins, plugins)

      # |> Keyword.put(:queues, false)
    else
      opts
    end
  end

  defp get_goth() do
    source = Application.get_env(:nox, :goth_source)

    if source do
      Supervisor.child_spec({Goth, name: Nox.Goth, source: source}, id: :goth_1)
    end
  end
end
