defmodule NoxWeb.Router do
  use NoxWeb, :router
  import Phoenix.LiveDashboard.Router
  import Oban.Web.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {NoxWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug NoxWeb.Auth.FetchInternalUserPlug
  end

  pipeline :admins_only do
    plug NoxWeb.Auth.RolePlug, roles: ["admin"]
  end

  pipeline :tutorial_editor_only do
    plug NoxWeb.Auth.RolePlug, roles: ["admin", "tutorial_editor"]
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug :fetch_session
  end

  pipeline :webhooks do
    plug :accepts, ["json"]
  end

  scope path: "/webhooks", alias: NoxWeb, as: :webhooks do
    pipe_through [:webhooks]

    post "/mux", Webhooks.MuxController, :mux
  end

  scope path: "/api", as: :api do
    pipe_through [:api]

    post "/collect", NoxWeb.CollectController, :index

    get "/loki/kiosker.settings", NoxWeb.LearnEarnController, :kiosker_settings

    get "/le/tuts_data", NoxWeb.LearnEarnController, :tuts_data
    get "/le/session", NoxWeb.LearnEarnController, :session
    post "/le/setup", NoxWeb.LearnEarnController, :setup
    post "/le/step", NoxWeb.LearnEarnController, :step
    post "/le/collect", NoxWeb.LearnEarnController, :collect
    post "/le/reward", NoxWeb.LearnEarnController, :reward
    post "/le/mark_redeemed", NoxWeb.LearnEarnController, :mark_redeemed
    post "/le/complete", NoxWeb.LearnEarnController, :complete
  end

  scope path: "/phx" do
    pipe_through [:browser, :admins_only]
    live_dashboard "/dashboard", metrics: NoxWeb.Telemetry, ecto_repos: [Nox.Repo]
    oban_dashboard("/oban")
  end

  scope "/", NoxWeb do
    pipe_through [:browser, :admins_only]

    live_session :admin,
      on_mount: [NoxWeb.Auth.FetchInternalUserHook, {NoxWeb.Auth.RoleHook, roles: ["admin"]}] do
      live "/users", UserLive.Index, :index
      live "/kiosk_lobby", KioskLobbyLive.Index, :index
      live "/users/:id/edit", UserLive.Index, :edit
      live "/loki_allowed_ips", LokiAllowedIpsLive.Index, :index

      live "/secret_configs", SecretConfigLive.Index, :index
      live "/secret_configs/new", SecretConfigLive.Index, :new
      live "/secret_configs/:id/edit", SecretConfigLive.Index, :edit
    end
  end

  scope "/", NoxWeb do
    pipe_through [:browser, :tutorial_editor_only]

    live_session :tutorial_editor,
      on_mount: [
        NoxWeb.Auth.FetchInternalUserHook,
        {NoxWeb.Auth.RoleHook, roles: ["admin", "tutorial_editor"]}
      ] do
      live "/tutorials", TutorialLive.Index, :index
      live "/tutorials/new", TutorialLive.Index, :new
      live "/tutorials/:id/edit", TutorialLive.Index, :edit

      live "/tutorials/:id", TutorialLive.Show, :show
      live "/tutorials/:id/show/edit", TutorialLive.Show, :edit

      live "/tutorials/:tutorial_id/pages/new", TutorialLive.Show, :new_page
      live "/tutorials/:tutorial_id/pages/:id/show/edit", TutorialLive.Show, :edit_page

      live "/le_partners", LePartnerLive.Index, :index
      live "/le_partners/new", LePartnerLive.Index, :new
      live "/le_partners/:id/edit", LePartnerLive.Index, :edit

      live "/le_partners/:id", LePartnerLive.Show, :show
      live "/le_partners/:id/show/edit", LePartnerLive.Show, :edit

      live "/stores", StoreLive.Index, :index
      live "/stores/new", StoreLive.Index, :new
      live "/stores/:id/edit", StoreLive.Index, :edit
    end
  end

  scope "/", NoxWeb do
    pipe_through [:browser]

    live_session :default, on_mount: [NoxWeb.Auth.FetchInternalUserHook] do
      get "/login", LoginController, :index
      get "/logout", LoginController, :logout
      get "/auth/google/callback", GoogleAuthController, :index

      live "/landing", LandingLive

      live "/", HomeLive.Index, :index
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", NoxWeb do
  #   pipe_through :api
  # end

  # Enables the Swoosh mailbox preview in development.
  #
  # Note that preview only shows emails that were sent by the same
  # node running the Phoenix server.
  if Mix.env() == :dev do
    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
