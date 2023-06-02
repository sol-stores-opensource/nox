defmodule Nox.Vault do
  use Cloak.Vault, otp_app: :nox

  @impl GenServer
  def init(config) do
    cloak_key = Application.fetch_env!(:nox, :cloak_vault_key)

    config =
      Keyword.put(config, :ciphers,
        default: {Cloak.Ciphers.AES.GCM, tag: "AES.GCM.V1", key: Base.decode64!(cloak_key)}
      )

    {:ok, config}
  end
end
