# this sets up iex with things that are commonly used in the app

alias Nox.Repo

import Ecto.Query
require Nox.Repo.BinaryKv

defmodule H do
  def infinity(true), do: IEx.configure(inspect: [limit: :infinity])
  def infinity(false), do: IEx.configure(inspect: [limit: 50])
end
