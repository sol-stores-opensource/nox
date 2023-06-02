defmodule NoxWeb.LayoutView do
  use NoxWeb, :view

  alias Nox.Users

  # Phoenix LiveDashboard is available only in development by default,
  # so we instruct Elixir to not warn if the dashboard route is missing.
  # @compile {:no_warn_undefined, {Routes, :live_dashboard_path, 2}}

  def nav_icon(assigns) do
    ~H"""
    <%= case @icon do %>
      <% "academic_cap" -> %>
        <HeroiconsV1.Outline.academic_cap class="mr-4 flex-shrink-0 h-6 w-6 text-indigo-300" />
      <% "sparkles" -> %>
        <HeroiconsV1.Outline.sparkles class="mr-4 flex-shrink-0 h-6 w-6 text-indigo-300" />
      <% "users" -> %>
        <HeroiconsV1.Outline.users class="mr-4 flex-shrink-0 h-6 w-6 text-indigo-300" />
      <% "shield-check" -> %>
        <HeroiconsV1.Outline.shield_check class="mr-4 flex-shrink-0 h-6 w-6 text-indigo-300" />
      <% "office-building" -> %>
        <HeroiconsV1.Outline.office_building class="mr-4 flex-shrink-0 h-6 w-6 text-indigo-300" />
    <% end %>
    """
  end

  def nav_items(socket, assigns) do
    current_user = assigns.current_user

    tutorial_editor =
      Users.has_role?(current_user, "tutorial_editor") || Users.has_role?(current_user, "admin")

    admin = Users.has_role?(current_user, "admin")

    [
      %{
        visible: tutorial_editor,
        divider: "Learn & Earn"
      },
      %{
        visible: tutorial_editor,
        icon: "academic_cap",
        to: ~p"/tutorials",
        title: "Tutorials",
        active:
          socket.view == NoxWeb.TutorialLive.Index || socket.view == NoxWeb.TutorialLive.Show
      },
      %{
        visible: tutorial_editor,
        icon: "sparkles",
        to: ~p"/le_partners",
        title: "Partners",
        active:
          socket.view == NoxWeb.LePartnerLive.Index || socket.view == NoxWeb.LePartnerLive.Show
      },
      %{
        visible: tutorial_editor,
        icon: "office-building",
        to: ~p"/stores",
        title: "Stores",
        active: socket.view == NoxWeb.StoreLive.Index
      },
      %{visible: admin, divider: "Admin"},
      %{
        visible: admin,
        icon: "users",
        to: ~p"/users",
        title: "Users",
        active: socket.view == NoxWeb.UserLive.Index
      },
      %{
        visible: admin,
        icon: "shield-check",
        to: ~p"/loki_allowed_ips",
        title: "Kiosk Firewall",
        active: socket.view == NoxWeb.LokiAllowedIpsLive.Index
      },
      %{
        visible: admin,
        icon: "shield-check",
        to: ~p"/kiosk_lobby",
        title: "Kiosks Live",
        active: socket.view == NoxWeb.KioskLobbyLive.Index
      },
      %{
        visible: admin,
        icon: "shield-check",
        to: ~p"/secret_configs",
        title: "Secret Configs",
        active: socket.view == NoxWeb.SecretConfigLive.Index
      },
      %{
        visible: admin,
        icon: "shield-check",
        to: ~p"/phx/dashboard",
        target: "_blank",
        title: "System Info",
        active: false
      },
      %{
        visible: admin,
        icon: "shield-check",
        to: ~p"/phx/oban",
        target: "_blank",
        title: "System Job Queues",
        active: false
      }
    ]
    |> Enum.filter(& &1.visible)
  end

  def flash_container(assigns) do
    ~H"""
    <div
      aria-live="assertive"
      class="pointer-events-none fixed inset-0 flex items-end px-4 py-6 sm:items-start sm:p-6 z-20"
    >
      <div id={@id} class="flex w-full flex-col items-center space-y-4 sm:items-end">
        <.flash_bubble {assigns} type={:info} />
        <.flash_bubble {assigns} type={:error} />
      </div>
    </div>
    """
  end

  def flash_bubble(assigns) do
    ~H"""
    <%= if message = Phoenix.Flash.get(@flash, @type) do %>
      <div
        id={"flash_#{:crypto.hash(:sha, message) |> Base.encode16(case: :lower)}"}
        class="pointer-events-auto w-full max-w-sm overflow-hidden rounded-lg bg-white shadow-lg ring-1 ring-black ring-opacity-5"
        x-cloak
        x-data="{ show: false }"
        x-show="show"
        x-transition:enter="transform ease-out duration-300 transition"
        x-transition:enter-start="translate-y-2 opacity-0 sm:translate-y-0 sm:translate-x-2"
        x-transition:enter-end="translate-y-0 opacity-100 sm:translate-x-0"
        x-transition:leave="transition ease-in duration-100"
        x-transition:leave-start="opacity-100"
        x-transition:leave-end="opacity-0"
      >
        <div class="p-4">
          <div class="flex items-start">
            <div class="flex-shrink-0">
              <!-- Heroicon name: outline/check-circle -->
              <svg
                class={
                  class_names([
                    "h-6",
                    "w-6",
                    "text-green-400": @type == :info,
                    "text-red-400": @type == :error
                  ])
                }
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                viewBox="0 0 24 24"
                stroke-width="1.5"
                stroke="currentColor"
                aria-hidden="true"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  d="M9 12.75L11.25 15 15 9.75M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                />
              </svg>
            </div>
            <div class="ml-3 w-0 flex-1 pt-0.5">
              <p class="text-sm font-medium text-gray-900"><%= message %></p>
            </div>
            <div class="ml-4 flex flex-shrink-0">
              <button
                x-init="show = true; setTimeout(() => show = false, 5000)"
                type="button"
                class="inline-flex rounded-md bg-white text-gray-400 hover:text-gray-500 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2"
                x-on:click="show = false"
              >
                <span class="sr-only">Close</span>
                <!-- Heroicon name: mini/x-mark -->
                <svg
                  class="h-5 w-5"
                  xmlns="http://www.w3.org/2000/svg"
                  viewBox="0 0 20 20"
                  fill="currentColor"
                  aria-hidden="true"
                >
                  <path d="M6.28 5.22a.75.75 0 00-1.06 1.06L8.94 10l-3.72 3.72a.75.75 0 101.06 1.06L10 11.06l3.72 3.72a.75.75 0 101.06-1.06L11.06 10l3.72-3.72a.75.75 0 00-1.06-1.06L10 8.94 6.28 5.22z" />
                </svg>
              </button>
            </div>
          </div>
        </div>
      </div>
    <% end %>
    """
  end
end
