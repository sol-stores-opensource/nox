defmodule Nox.Repo.TutPage do
  use Nox.Schema

  defdelegate image_conn(), to: Nox.Repo.GCSAsset, as: :default_conn
  defdelegate image_bucket(), to: Nox.Repo.GCSAsset, as: :default_bucket

  schema "tut_pages" do
    field :title, :string
    field :description, :string
    field :exit_url, :string
    field :exit_label, :string

    embeds_many :answers, Repo.TutAnswer, on_replace: :delete
    field :position, :integer

    embeds_one :image, Repo.GCSAsset, on_replace: :delete
    embeds_one :video, Repo.MuxAsset, on_replace: :delete
    belongs_to :tutorial, Repo.Tutorial

    timestamps type: :utc_datetime_usec
  end

  @doc false
  def changeset(tut_page, attrs) do
    tut_page
    |> cast(attrs, [:position, :title, :description, :exit_url, :exit_label])
    |> cast_embed(:answers)
    |> validate_required([:title])
    |> Repo.GCSAsset.cast_attachments(attrs, [:image])
    |> Repo.MuxAsset.cast_attachments(attrs, [:video])
  end

  @doc """
  Turns a TutPage into either a valid content_page, valid question, or nil if invalid.
  """
  def to_output(%__MODULE__{answers: [_ | _]} = tut_page) do
    correct_count =
      tut_page.answers
      |> Enum.count(fn x -> x.correct end)

    if correct_count == 1 do
      %{
        type: "question",
        question: tut_page.title,
        answers:
          tut_page.answers
          |> Enum.map(fn x -> %{answer: x.answer, correct: x.correct} end),
        page: tut_page.position
      }
    end
  end

  def to_output(%__MODULE__{} = tut_page) do
    if tut_page.title && (tut_page.image || tut_page.video) do
      %{
        type: "content_page",
        title: tut_page.title,
        image_url: Nox.Repo.GCSAsset.public_url(tut_page.image),
        video_playback_url: Nox.Repo.MuxAsset.playback_url(tut_page.video),
        video_thumbnail_url: Nox.Repo.MuxAsset.thumbnail_url(tut_page.video, %{}),
        description: tut_page.description,
        page: tut_page.position,
        exit_url: tut_page.exit_url,
        exit_label: tut_page.exit_label
      }
    end
  end
end
