defmodule Nox.Crypto.Addresses do
  # returns only {:solana, addr}, {:sns, addr} pairs
  def filter_valid_addresses(addresses_string_or_list) do
    for {k, v} <- analyze_addresses(addresses_string_or_list), k in [:solana, :sns], do: {k, v}
  end

  # validates addresses into {:solana, addr}, {:sns, addr}, {:error, addr}
  def analyze_addresses(addresses)

  def analyze_addresses(addresses) when is_binary(addresses) do
    addresses =
      addresses
      |> String.split(~r/[\s,]+/, trim: true)

    analyze_addresses(addresses)
  end

  def analyze_addresses(addresses) when is_list(addresses) do
    addresses = addresses |> Enum.uniq()

    for a <- addresses do
      c = a |> to_charlist()

      if :base58.check_base58(c) && c |> :base58.base58_to_binary() |> Ed25519.on_curve?() &&
           c |> :base58.base58_to_binary() |> byte_size() == 32 do
        {:solana, a}
      else
        b = String.downcase(a)

        case Regex.run(~r{(.+?\.sol).*?$}, b) do
          [_, sns_addr] ->
            {:sns, sns_addr}

          _ ->
            {:error, a}
        end
      end
    end
  end

  def valid_solana_address?(str) when is_binary(str) do
    case analyze_addresses([str]) do
      [{:solana, ^str}] -> true
      _ -> false
    end
  end

  def trim_internal_pubkey(receiver) do
    String.split(receiver, ":") |> List.last()
  end
end
