defmodule Nox.Repo.BinaryKv do
  @moduledoc """
  https://gist.github.com/joenoon/921f1b364fe1c9debb421bbd9e147410
  Simple ecto Binary KV store in the db
  MIT License, Joe Noon, Copyright 2020
  """
  require Logger
  use Ecto.Schema

  import Ecto.Query

  alias Nox.Repo

  @primary_key {:k, :string, autogenerate: false}

  schema "binary_kv" do
    field :v, :binary
    field :exp, :utc_datetime_usec

    timestamps type: :utc_datetime_usec
  end

  # PUBLIC API

  def get(k) do
    from(x in __MODULE__,
      where: is_nil(x.exp) or x.exp > fragment("now()"),
      where: x.k == ^k
    )
    |> Repo.one()
    |> return_if_valid()
  end

  def del(k) do
    from(x in __MODULE__,
      where: x.k == ^k
    )
    |> Repo.delete_all()
  end

  def exp(k, exp) do
    from(x in __MODULE__,
      where: x.k == ^k,
      update: [
        set: [exp: ^exp]
      ]
    )
    |> Repo.update_all([])
  end

  def put(k, v, exp \\ nil) do
    %__MODULE__{
      k: k,
      v: to_value(v),
      exp: exp
    }
    |> Repo.insert!(
      on_conflict: {:replace_all_except, [:k]},
      conflict_target: [:k]
    )
  end

  defmacro fetch(k, [exp: exp], do: do_fun) do
    quote do
      case Nox.Repo.BinaryKv.get(unquote(k)) do
        nil ->
          v = unquote(do_fun)
          Nox.Repo.BinaryKv.put(unquote(k), v, unquote(exp))
          v

        v ->
          v
      end
    end
  end

  # PRIV

  defp return_if_valid(%{exp: nil, v: v}), do: from_value(v)

  defp return_if_valid(%{exp: exp, v: v}) do
    case DateTime.compare(DateTime.utc_now(), exp) do
      :lt -> from_value(v)
      _ -> nil
    end
  end

  defp return_if_valid(_), do: nil

  defp to_value(nil), do: nil
  defp to_value(v), do: :erlang.term_to_binary(v)

  defp from_value(nil), do: nil
  defp from_value(v) when is_binary(v), do: :erlang.binary_to_term(v)
end
