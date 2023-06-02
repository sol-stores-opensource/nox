defmodule NoxWeb.LiveHelpers do
  require Logger

  import Phoenix.Component

  def noreply(socket), do: {:noreply, socket}

  def okreply(socket), do: {:ok, socket}

  def contreply(socket), do: {:cont, socket}

  def haltreply(socket), do: {:halt, socket}

  def copy_assign(socket, from_key, to_key) do
    socket
    |> assign(to_key, socket.assigns[from_key])
  end
end
