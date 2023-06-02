defmodule Nox.Repo.Tutorial do
  use Nox.Schema

  defdelegate logo_conn(), to: Nox.Repo.GCSAsset, as: :default_conn
  defdelegate logo_bucket(), to: Nox.Repo.GCSAsset, as: :default_bucket
  defdelegate hero_image_conn(), to: Nox.Repo.GCSAsset, as: :default_conn
  defdelegate hero_image_bucket(), to: Nox.Repo.GCSAsset, as: :default_bucket

  schema "tutorials" do
    field :title, :string
    field :description, :string
    field :time_est, :integer
    field :reward_est, :string
    field :external_url, :string
    # @deprecated
    # field :active, :boolean
    field :tuts_on_complete_webhook, :string
    # @deprecated
    field :on_complete_nft, :map
    # @deprecated
    field :on_complete_nft_address, :string, virtual: true
    field :opens_in, Ecto.Enum, values: [:web, :web_tuts, :phantom], default: :phantom

    embeds_many :misc, Repo.KVPair, on_replace: :delete
    embeds_one :logo, Repo.GCSAsset, on_replace: :delete
    embeds_one :hero_image, Repo.GCSAsset, on_replace: :delete
    embeds_one :hero_video, Repo.MuxAsset, on_replace: :delete

    belongs_to :le_partner, Repo.LePartner
    has_many :pages, Repo.TutPage
    has_many :le_rewards, Repo.LeReward
    has_many :tutorial_stores, Repo.TutorialStore

    timestamps type: :utc_datetime_usec
  end

  @doc false
  def changeset(tutorial, attrs, opts \\ []) do
    tutorial
    |> cast(attrs, [
      :title,
      :description,
      :time_est,
      :reward_est,
      :external_url,
      :le_partner_id,
      :tuts_on_complete_webhook,
      :on_complete_nft_address,
      :opens_in
    ])
    |> validate_required([
      :title,
      :description,
      :le_partner_id,
      :opens_in
    ])
    |> Nox.Repo.Helpers.validate_url(:tuts_on_complete_webhook)
    |> cast_embed(:misc)
    |> Repo.GCSAsset.cast_attachments(attrs, [:logo, :hero_image])
    |> Repo.MuxAsset.cast_attachments(attrs, [:hero_video])
    |> cast_assoc(:tutorial_stores, with: {Repo.TutorialStore, :changeset, [opts]})
  end

  def to_output(
        %__MODULE__{
          id: id,
          title: title,
          logo: %{} = logo,
          hero_image: hero_image,
          hero_video: hero_video,
          description: description,
          time_est: time_est,
          reward_est: reward_est,
          external_url: external_url,
          opens_in: opens_in,
          misc: misc,
          tutorial_stores: tutorial_stores
        } = tutorial
      ) do
    tuts_url_base = Application.fetch_env!(:nox, :tuts_url_base)

    url =
      if Nox.Tutorials.is_external?(tutorial) do
        external_url
      else
        Path.join([tuts_url_base, "tuts", id])
      end

    %{
      id: id,
      name: title,
      description: description,
      logo: Nox.Repo.GCSAsset.public_url(logo),
      hero_image: Nox.Repo.GCSAsset.public_url(hero_image),
      hero_video_playback_url: Nox.Repo.MuxAsset.playback_url(hero_video),
      hero_video_thumbnail_url: Nox.Repo.MuxAsset.thumbnail_url(hero_video, %{}),
      url: url,
      time: if(time_est, do: "#{time_est} min", else: nil),
      reward: reward_est,
      opens_in: "#{opens_in}",
      misc: misc_to_map(misc),
      tutorial_stores:
        tutorial_stores
        |> Enum.map(fn ts -> Nox.Repo.TutorialStore.to_output(ts) end)
    }
  end

  def to_output(_), do: nil

  defp misc_to_map(nil), do: %{}

  defp misc_to_map(misc) do
    misc
    |> Enum.map(fn x -> {x.key, x.value} end)
    |> Map.new()
  end
end
