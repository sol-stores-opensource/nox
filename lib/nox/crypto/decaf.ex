defmodule Nox.Crypto.Decaf do
  require Logger

  alias Nox.Repo.Store

  def airdrop(
        %Store{decaf_shop_id: shop_id, decaf_airdrop_api_url: url},
        receiver_wallet,
        master_nft_mint
      ) do
    post(url, %{
      shopId: shop_id,
      receiverWallet: receiver_wallet,
      masterNftMint: master_nft_mint
    })
  end

  def nft_metadata(%Store{decaf_shop_id: shop_id, decaf_airdrop_api_url: url}, master_nft_mint) do
    get(url, %{
      shopId: shop_id,
      masterNftMint: master_nft_mint
    })
  end

  ###

  def action(method, url, params) do
    request = %HTTPoison.Request{
      method: method,
      url: url,
      # headers: [
      #   {"content-type", "application/json"}
      # ],
      options: [
        timeout: 120_000,
        recv_timeout: 120_000
        #  ssl: [verify: :verify_none]
      ]
    }

    request =
      case method do
        _ ->
          Map.put(request, :params, params)

          # _ ->
          #   Map.put(request, :body, Jason.encode!(params))
      end

    response = HTTPoison.request(request)

    with {:ok, %{body: body, headers: _headers, status_code: status_code}}
         when status_code >= 200 and status_code < 300 <- response,
         {:ok, decoded} <- Jason.decode(body) do
      {:ok, decoded}
    else
      what ->
        {:error, what}
    end
  end

  def post(url, params \\ %{}) when is_binary(url), do: action(:post, url, params)
  def get(url, params \\ %{}) when is_binary(url), do: action(:get, url, params)

  ###

  def track_airdrop!(%Store{decaf_shop_id: shop_id}, nft_address, to_address, data \\ %{}) do
    payload =
      %{}
      |> Map.put("event", "airdrop")
      |> Map.put("type", "decaf")
      |> Map.put(
        "properties",
        data
        |> Map.put("nft_address", nft_address)
        |> Map.put("to_address", to_address)
        |> Map.put("shopId", shop_id)
      )

    Nox.Workers.CollectChunkWorker.nox_add(payload)

    :ok
  end

  ###

  def test_decaf_airdrop() do
    store = Nox.Stores.get_by_slug!("nyc")
    # joe's dev wallet
    receiver_wallet = "GoPjyroW6w9tkkyjxXdaPuVkNkawkrLVBMHzQJdxKy92"
    # "Joe Test Dog Drinking Water" on https://admin-dev.decaf.so/
    master_nft_mint = "3WdpLNx74Bwc1Ucp21yJt7YSyEVS3wo97GZtQX8zHgaF"

    airdrop(store, receiver_wallet, master_nft_mint)
  end

  def test_decaf_nft_metadata() do
    store = Nox.Stores.get_by_slug!("nyc")

    # "Joe Test Dog Drinking Water" on https://admin-dev.decaf.so/
    master_nft_mint = "3WdpLNx74Bwc1Ucp21yJt7YSyEVS3wo97GZtQX8zHgaF"

    nft_metadata(store, master_nft_mint)
  end
end
