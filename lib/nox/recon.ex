defmodule Nox.Recon do
  @moduledoc """
  Misc functions for recon of open sockets
  """

  def all_nodes() do
    [Node.self() | Node.list()]
  end

  def local_tcp_inet() do
    :recon.port_types()
    |> Enum.map(fn
      {'tcp_inet', n} -> n
      _ -> nil
    end)
    |> Enum.filter(& &1)
    |> List.first()
  end

  def all_tcp_inet() do
    all_nodes()
    |> Enum.map(fn n ->
      :rpc.call(n, Nox.Recon, :local_tcp_inet, [])
    end)
    |> Enum.filter(fn
      n when is_integer(n) -> true
      _ -> false
    end)
    |> Enum.sum()
  end

  def safe_all_tcp_inet() do
    try do
      all_tcp_inet()
    rescue
      _ ->
        0
    end
  end
end
