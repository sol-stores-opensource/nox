defmodule Nox.MixProject do
  use Mix.Project

  def project do
    [
      app: :nox,
      version: "0.1.0",
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Nox.Application, []},
      extra_applications:
        [:logger, :runtime_tools, :inets, :ssl] ++
          if(Mix.env() == :prod, do: [:os_mon], else: [])
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, github: "phoenixframework/phoenix", override: true},
      {:phoenix_ecto, "~> 4.4"},
      {:ecto_sql, "~> 3.6"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 3.0"},
      {:phoenix_live_reload, "~> 1.3", only: :dev},
      {:phoenix_live_view, "~> 0.18"},
      {:floki, ">= 0.30.0", only: :test},
      {:phoenix_live_dashboard, "~> 0.7.0"},
      {:esbuild, "~> 0.3", runtime: Mix.env() == :dev},
      {:swoosh, "~> 1.8.0"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.20.0"},
      {:jason, "~> 1.2"},
      {:plug_cowboy, "~> 2.5"},
      # ours
      {:libcluster, "~> 3.3"},
      {:ecto_psql_extras, "~> 0.7.4"},
      {:recon, "~> 2.5"},
      {:timex, "~> 3.7"},
      {:corsica, "~> 1.1"},
      {:recase, "~> 0.7.0"},
      {:geo_postgis, "~> 3.4"},
      {:elixir_auth_google, "~> 1.6"},
      {:oban, "~> 2.13.4"},
      {:oban_pro, "~> 0.12.5", repo: "oban"},
      {:oban_web, "~> 2.9.5", repo: "oban"},
      {:kcl, "~> 1.4"},
      {:erl_base58, "~> 0.0.1"},
      {:goth, "~> 1.3-rc"},
      {:hackney, "~> 1.18"},
      {:google_api_big_query, "~> 0.76"},
      {:petal_components, "~> 0.18"},
      {:google_api_storage, "~> 0.34.0"},
      {:mux, "~> 2.4"},
      {:assertions, "~> 0.19", only: :test},
      {:mix_test_watch, "~> 1.1", only: :dev, runtime: false},
      {:tailwind, "~> 0.1.9", runtime: Mix.env() == :dev},
      {:csv, "~> 2.4.1"},
      {:cloak_ecto, "~> 1.2.0"},
      {:remote_ip, "~> 1.1"},
      {:plug, "~> 1.14"},
      {:req, "~> 0.3.4"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.deploy": ["tailwind default --minify", "esbuild default --minify", "phx.digest"]
    ]
  end
end
