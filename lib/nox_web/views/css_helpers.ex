defmodule NoxWeb.CSSHelpers do
  def class_names(list) when is_list(list) do
    list
    |> Enum.map(fn
      {k, v} ->
        if v, do: k, else: nil

      k ->
        k
    end)
    |> Enum.filter(& &1)
    |> Enum.join(" ")
  end

  def class_names(map) when is_map(map) do
    map
    |> Enum.filter(fn {_, v} -> v end)
    |> Keyword.keys()
    |> Enum.join(" ")
  end

  def format_mmddyyyy_time(nil), do: nil

  def format_mmddyyyy_time(datetime, tz \\ "America/New_York", show_tz \\ true) do
    format_str = if show_tz, do: "%m/%d/%Y %I:%M %P (%Z)", else: "%m/%d/%Y %I:%M %P"

    Timex.format!(
      Timex.to_datetime(datetime, tz),
      format_str,
      :strftime
    )
  end
end
