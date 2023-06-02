defmodule NoxWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, views, channels and so on.

  This can be used in your application as:

      use NoxWeb, :controller
      use NoxWeb, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define any helper function in modules
  and import those modules here.
  """

  def controller do
    quote do
      use Phoenix.Controller, namespace: NoxWeb

      import Plug.Conn
      import NoxWeb.Gettext
    end
  end

  def view do
    quote do
      use Phoenix.View,
        root: "lib/nox_web/templates",
        namespace: NoxWeb

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_flash: 1, get_flash: 2, view_module: 1, view_template: 1]

      # Include shared imports and aliases for views
      unquote(view_helpers())
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView,
        layout: {NoxWeb.LayoutView, "live.html"}

      import NoxWeb.LiveHelpers

      unquote(view_helpers())
    end
  end

  def landing_live_view do
    quote do
      use Phoenix.LiveView,
        layout: {NoxWeb.LayoutView, "landing.html"}

      import NoxWeb.LiveHelpers

      unquote(view_helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      import NoxWeb.LiveHelpers

      unquote(view_helpers())
    end
  end

  def component do
    quote do
      use Phoenix.Component

      unquote(view_helpers())
    end
  end

  def router do
    quote do
      # , helpers: false
      use Phoenix.Router

      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel, log_join: :info, log_handle_in: :info
      import NoxWeb.Gettext
    end
  end

  def static_paths, do: ~w(assets fonts images favicon.ico robots.txt)

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: NoxWeb.Endpoint,
        router: NoxWeb.Router,
        statics: NoxWeb.static_paths()
    end
  end

  defp view_helpers do
    quote do
      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML

      # Import LiveView and .heex helpers (live_render, live_patch, <.form>, etc)
      import Phoenix.Component

      # Import basic rendering functionality (render, render_layout, etc)
      import Phoenix.View

      import NoxWeb.ErrorHelpers
      import NoxWeb.Gettext
      import NoxWeb.CSSHelpers

      use PetalComponents

      unquote(verified_routes())
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
