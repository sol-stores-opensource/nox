defmodule Nox.Crypto.DecafLeConfig do
  require Logger

  def get() do
    url = Application.fetch_env!(:nox, :decaf_le_config_api_url)

    headers = [
      {"authorization", "Bearer #{Application.fetch_env!(:nox, :decaf_le_config_api_key)}"}
    ]

    get(url, %{}, headers)
  end

  def set(config) do
    url = Application.fetch_env!(:nox, :decaf_le_config_api_url)

    headers = [
      {"authorization", "Bearer #{Application.fetch_env!(:nox, :decaf_le_config_api_key)}"},
      {"content-type", "application/json"}
    ]

    post(url, config, headers)
  end

  def qr_url_for(variation) do
    base = Application.fetch_env!(:nox, :decaf_le_solana_qr_url)

    url =
      "#{base}#{variation}"
      |> URI.encode_www_form()

    "solana:#{url}"
  end

  ###

  def action(method, url, params, headers \\ []) do
    request = %HTTPoison.Request{
      method: method,
      url: url,
      headers: headers,
      options: [
        timeout: 120_000,
        recv_timeout: 120_000
        #  ssl: [verify: :verify_none]
      ]
    }

    request =
      case method do
        :get ->
          Map.put(request, :params, params)

        :post ->
          Map.put(request, :body, Jason.encode!(params))
      end

    response = HTTPoison.request(request)

    with {:ok, %{body: body, headers: _headers, status_code: status_code}}
         when status_code >= 200 and status_code < 300 and is_binary(body) <- response do
      {:ok, body}
    else
      what ->
        {:error, what}
    end
  end

  def post(url, params \\ %{}, headers \\ []) when is_binary(url),
    do: action(:post, url, params, headers)

  def get(url, params \\ %{}, headers \\ []) when is_binary(url),
    do: action(:get, url, params, headers)
end
