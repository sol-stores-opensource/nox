defmodule Nox.ImportTutorials do
  @moduledoc """

  Usage:

    # on [staging] iex:

    Nox.ImportTutorials.existing_to_data("staging-uuid") |> :erlang.term_to_binary |> Base.encode64 |> IO.puts

    # copy to clipboard

    # on [prod] iex:

    data = "...paste..."

    Nox.ImportTutorials.import_from_data("prod-uuid", data |> Base.decode64! |> :erlang.binary_to_term)

  """
  require Logger
  import Ecto.Query, warn: false
  import Nox.Tutorials, only: [get_tutorial!: 1]
  import Ecto.Changeset
  alias Nox.Repo

  def import_from_data(into_tutorial_id, data) do
    Logger.warn("Importing tutorial #{into_tutorial_id} from data")
    tutorial = get_tutorial!(into_tutorial_id)

    tutorial_data =
      data["tutorial"]
      |> Map.delete("tutorial_stores")

    pages_data = tutorial_data["pages"]

    logo =
      download_and_insert_gcs_asset(
        tutorial_data["logo"],
        Repo.Tutorial.logo_conn(),
        "uploads/tutorial_logos/#{Ecto.UUID.generate()}",
        Repo.Tutorial.logo_bucket()
      )

    hero_image =
      download_and_insert_gcs_asset(
        tutorial_data["hero_image"],
        Repo.Tutorial.hero_image_conn(),
        "uploads/tutorial_hero_images/#{Ecto.UUID.generate()}",
        Repo.Tutorial.hero_image_bucket()
      )

    hero_video =
      download_and_insert_mux_asset(tutorial_data["hero_video"], {Nox.Repo.Tutorial, :hero_video})

    tutorial
    |> cast(tutorial_data, [
      :title,
      :description,
      :time_est,
      :reward_est,
      :opens_in
    ])
    |> validate_required([
      :title,
      :description,
      :opens_in
    ])
    |> cast_embed(:misc)
    |> Ecto.Changeset.put_embed(:logo, to_gcs_asset(logo))
    |> Ecto.Changeset.put_embed(:hero_image, to_gcs_asset(hero_image))
    |> Ecto.Changeset.put_embed(:hero_video, to_mux_asset(hero_video))
    |> Repo.update!()

    tutorial = get_tutorial!(into_tutorial_id)

    tutorial.pages
    |> Enum.each(fn p ->
      Logger.warn("Deleting page #{p.id}")
      {:ok, _} = Repo.delete(p)
    end)

    tutorial = get_tutorial!(into_tutorial_id)

    pages_data
    |> Enum.each(fn page_data ->
      import_page_from_data(tutorial, page_data)
    end)

    get_tutorial!(into_tutorial_id)
  end

  def import_page_from_data(tutorial, page_data) do
    Logger.warn("Importing page #{page_data["title"]}")

    image =
      download_and_insert_gcs_asset(
        page_data["image"],
        Repo.TutPage.image_conn(),
        "uploads/tut_page_images/#{Ecto.UUID.generate()}",
        Repo.TutPage.image_bucket()
      )

    video = download_and_insert_mux_asset(page_data["video"], {Nox.Repo.TutPage, :video})

    page_data =
      page_data
      |> Map.delete("image")
      |> Map.delete("video")

    %Repo.TutPage{tutorial_id: tutorial.id}
    |> cast(page_data, [:position, :title, :description, :exit_url, :exit_label])
    |> cast_embed(:answers)
    |> validate_required([:title])
    |> Ecto.Changeset.put_embed(:image, to_gcs_asset(image))
    |> Ecto.Changeset.put_embed(:video, to_mux_asset(video))
    |> Repo.insert!()
  end

  def download_and_insert_gcs_asset(
        %{"bucket" => from_bucket, "name" => from_name, "contentType" => from_mime},
        %Tesla.Client{} = to_conn,
        to_path,
        to_bucket
      ) do
    Logger.warn(
      "Downloading asset #{from_name} from #{from_bucket} to #{to_path} in #{to_bucket}"
    )

    url = "https://storage.googleapis.com/#{from_bucket}/#{from_name}"

    %HTTPoison.Response{body: iodata} = HTTPoison.get!(url)

    Logger.warn("Uploading asset #{to_path} to #{to_bucket}")
    # upload to new
    {:ok, _res} =
      GoogleApi.Storage.V1.Api.Objects.storage_objects_insert_iodata(
        to_conn,
        to_bucket,
        "multipart",
        %GoogleApi.Storage.V1.Model.Object{name: to_path, contentType: from_mime},
        iodata,
        name: to_path,
        predefinedAcl: "publicRead"
      )

    # retrieve
    {:ok, res} = Nox.Google.Storage.get_file_info(to_conn, to_bucket, to_path)
    Map.from_struct(res)
  end

  def download_and_insert_gcs_asset(_, _, _, _), do: nil

  def download_and_insert_mux_asset(
        %{"master" => %{"status" => "ready", "url" => url}},
        passthrough_data
      ) do
    Logger.warn("Downloading mux asset #{url}")
    # upload to new
    {:ok, asset, _} =
      Mux.Video.Assets.create(Mux.client(), %{
        input: url,
        playback_policy: ["public"],
        passthrough: Repo.MuxAsset.encode_passthrough(passthrough_data)
      })

    # retrieve
    {:ok, asset, _} = Mux.Video.Assets.get(Mux.client(), asset["id"])
    asset
  end

  def download_and_insert_mux_asset(_, _), do: nil

  def existing_to_data(tutorial_id) do
    Logger.warn("Exporting tutorial #{tutorial_id} to data")
    tutorial = get_tutorial!(tutorial_id)

    tutorial_data =
      tutorial
      |> to_jsonable()
      |> Map.put(
        :hero_image,
        to_jsonable(tutorial.hero_image)
      )
      |> Map.put(
        :hero_video,
        prepare_mux_asset_for_export(tutorial.hero_video)
      )
      |> Map.put(:logo, to_jsonable(tutorial.logo))
      |> Map.put(:pages, tutorial.pages |> Enum.map(&existing_page_to_data/1))

    %{
      "tutorial" => tutorial_data
    }
    |> Jason.encode!()
    |> Jason.decode!()
  end

  def existing_page_to_data(page) do
    Logger.warn("Exporting page #{page.title} to data")

    page
    |> to_jsonable()
    |> Map.put(:image, to_jsonable(page.image))
    |> Map.put(:video, prepare_mux_asset_for_export(page.video))
  end

  def prepare_mux_asset_for_export(%{id: id} = params) do
    Logger.warn("Preparing mux asset #{id} for export")
    {:ok, asset, _} = Mux.Video.Assets.get(Mux.client(), id)

    case asset do
      %{"master" => %{"status" => "ready"}} ->
        asset

      _ ->
        status =
          case asset do
            %{"master" => %{"status" => "preparing"}} -> :preparing
            _ -> :unknown
          end

        Logger.warn("Sleeping for 10 seconds (#{inspect(status)})")

        if status == :unknown do
          Logger.warn("Requesting master access for #{id}")

          Mux.Video.Assets.update_master_access(Mux.client(), id, %{
            "master_access" => "temporary"
          })
        end

        Process.sleep(:timer.seconds(10))
        prepare_mux_asset_for_export(params)
    end
  end

  def prepare_mux_asset_for_export(_), do: nil

  def to_jsonable(%DateTime{} = dt), do: DateTime.to_iso8601(dt)

  def to_jsonable(struct) when is_struct(struct) do
    struct
    |> Map.from_struct()
    |> Map.delete(:__meta__)
    |> Enum.reduce(%{}, fn {k, v}, acc ->
      Map.put(acc, k, to_jsonable(v))
    end)
    |> Map.new()
    |> to_jsonable()
  end

  def to_jsonable(list) when is_list(list) do
    list |> Enum.map(&to_jsonable/1)
  end

  def to_jsonable(other) do
    other
  end

  def to_gcs_asset(%{} = data) do
    Repo.GCSAsset.changeset(%Repo.GCSAsset{}, data)
    |> Ecto.Changeset.apply_changes()
  end

  def to_gcs_asset(_), do: nil

  def to_mux_asset(%{} = data) do
    Repo.MuxAsset.changeset(%Repo.MuxAsset{}, data)
    |> Ecto.Changeset.apply_changes()
  end

  def to_mux_asset(_), do: nil

  def prep_all_mux_videos_for_download() do
    {:ok, res, _} = Mux.Video.Assets.list(Mux.client(), %{limit: 1000})

    res
    |> Enum.each(fn %{"id" => id} ->
      Mux.Video.Assets.update_master_access(Mux.client(), id, %{"master_access" => "temporary"})
    end)
  end
end
