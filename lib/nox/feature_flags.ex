defmodule Nox.FeatureFlags do
  @key "feature-flags"

  def load() do
    case Nox.Repo.SecretConfig.get_by_slug!(@key) do
      %Nox.Repo.SecretConfig{json_enc: %{} = config} ->
        config

      _ ->
        %{}
    end
  end

  def get(key) do
    load()
    |> Map.get(key)
  end
end
