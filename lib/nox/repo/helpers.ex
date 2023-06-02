defmodule Nox.Repo.Helpers do
  def validate_url(changeset, field) do
    changeset
    |> Ecto.Changeset.validate_change(field, fn ^field, url ->
      if url do
        case URI.parse("#{url}") do
          %URI{host: host, scheme: scheme}
          when is_binary(host) and byte_size(host) > 3 and scheme in ["http", "https"] ->
            []

          _ ->
            [{field, "must be a valid URL"}]
        end
      else
        []
      end
    end)
  end
end
