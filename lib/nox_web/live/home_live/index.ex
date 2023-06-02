defmodule NoxWeb.HomeLive.Index do
  use NoxWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <.h1>Welcome</.h1>
    """
  end
end
