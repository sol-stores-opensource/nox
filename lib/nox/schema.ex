defmodule Nox.Schema do
  defmacro __using__(_) do
    quote do
      require Logger
      use Ecto.Schema
      import Ecto.Query, warn: false
      import Ecto.Changeset, warn: false
      alias Nox.Repo, warn: false
      @primary_key {:id, :binary_id, read_after_writes: true}
      @foreign_key_type :binary_id
    end
  end
end
