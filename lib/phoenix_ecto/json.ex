defimpl Poison.Encoder, for: Ecto.Date do
  def encode(date, _options), do: date |> Ecto.Date.to_iso8601
end

defimpl Poison.Encoder, for: Ecto.Time do
  def encode(time, _options), do: time |> Ecto.Time.to_iso8601
end

defimpl Poison.Encoder, for: Ecto.DateTime do
  def encode(date_time, _options), do: date_time |> Ecto.DateTime.to_iso8601
end
