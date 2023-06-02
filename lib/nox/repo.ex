defmodule Nox.Repo do
  use Ecto.Repo,
    otp_app: :nox,
    adapter: Ecto.Adapters.Postgres

  def broadcast_record(ok_tuple, topic, event) when event in ["updated", "created", "deleted"] do
    ok_tuple
    |> tap(fn
      {:ok, record} ->
        NoxWeb.Endpoint.broadcast(topic, event, %{
          record: record
        })

      _ ->
        nil
    end)
  end

  defmodule Standard do
    def setup(setup_ops) do
      is_tombstone = Keyword.get(setup_ops, :tombstone, false)

      quote do
        alias Nox.Repo
        import Nox.Repo, only: [broadcast_record: 3]

        defmacro topic() do
          "#{__MODULE__}"
        end

        def subscribe() do
          NoxWeb.Endpoint.subscribe(topic())
        end

        def create(attrs) when is_map(attrs) and not is_struct(attrs) do
          %__MODULE__{}
          |> create(attrs)
        end

        def create(record, attrs) do
          record
          |> changeset(attrs)
          |> Repo.insert()
          |> broadcast_record(topic(), "created")
        end

        def update(record, attrs) do
          record
          |> changeset(attrs)
          |> Repo.update()
          |> broadcast_record(topic(), "updated")
        end

        if unquote(is_tombstone) do
          def list_query do
            from s in __MODULE__, where: is_nil(s.deleted_at)
          end

          def delete(record) do
            record
            |> changeset(%{deleted_at: DateTime.utc_now()})
            |> Repo.update()
            |> broadcast_record(topic(), "deleted")
          end
        else
          def list_query do
            from(s in __MODULE__)
          end

          def delete(record) do
            record
            |> Repo.delete()
            |> broadcast_record(topic(), "deleted")
          end
        end

        defoverridable list_query: 0

        def list do
          list_query()
          |> Repo.all()
        end

        def get(id) do
          list_query()
          |> where([s], s.id == ^id)
          |> Repo.one()
        end

        def get!(id) do
          list_query()
          |> where([s], s.id == ^id)
          |> Repo.one!()
        end

        def get_by(opts) do
          Repo.get_by(__MODULE__, opts)
        end

        def get_by!(opts) do
          Repo.get_by!(__MODULE__, opts)
        end
      end
    end

    defmacro __using__(opts) do
      setup(opts || [[]])
      # apply(__MODULE__, :setup, opts)
    end
  end
end
