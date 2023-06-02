defmodule NoxWeb.Components.Card2ColData do
  use Phoenix.Component
  use PetalComponents

  def container(assigns) do
    assigns =
      assigns
      |> assign_new(:rows, fn -> [] end)

    ~H"""
    <div class="bg-white shadow overflow-hidden sm:rounded-lg">
      <%= render_slot(@inner_block) %>
      <div class="border-t border-gray-200 px-4 py-5 sm:p-0">
        <dl class="sm:divide-y sm:divide-gray-200">
          <%= render_slot(@rows) %>
        </dl>
      </div>
    </div>
    """
  end

  def full_row(assigns) do
    assigns =
      assigns
      |> assign_new(:title, fn -> [] end)
      |> assign_new(:right, fn -> [] end)
      |> assign_new(:description, fn -> [] end)

    ~H"""
    <div class="px-4 py-5 sm:px-6">
      <div class="flex flex-row justify-between">
        <h3 class="text-lg leading-6 font-medium text-gray-900">
          <%= render_slot(@title) %>
        </h3>
        <div>
          <%= render_slot(@right) %>
        </div>
      </div>
      <p class="mt-3 max-w-2xl text-sm text-gray-500">
        <%= render_slot(@description) %>
      </p>
    </div>
    """
  end

  def data_row(assigns) do
    assigns =
      assigns
      |> assign_new(:left, fn -> [] end)
      |> assign_new(:right, fn -> [] end)

    ~H"""
    <div class="py-4 sm:py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
      <dt class="text-sm font-medium text-gray-500"><%= render_slot(@left) %></dt>
      <dd class="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2"><%= render_slot(@right) %></dd>
    </div>
    """
  end
end
