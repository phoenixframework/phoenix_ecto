defimpl Poison.Encoder, for: [Ecto.Date, Ecto.Time, Ecto.DateTime] do
  def encode(dt, _opts), do: @for.to_iso8601(dt)
end
