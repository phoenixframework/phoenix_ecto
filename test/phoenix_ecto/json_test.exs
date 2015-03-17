defmodule PhoenixEcto.JSONTest do
  use ExUnit.Case, async: true

  test "encodes Ecto time structs" do
    time = %Ecto.Time{hour: 0, min: 0, sec: 0}
    assert Poison.encode!(time) == Ecto.Time.to_iso8601(time)

    date = %Ecto.Date{year: 2010, month: 4, day: 17}
    assert Poison.encode!(date) == Ecto.Date.to_iso8601(date)

    dt = %Ecto.DateTime{year: 2010, month: 4, day: 17, hour: 0, min: 0, sec: 0}
    assert Poison.encode!(dt) == Ecto.DateTime.to_iso8601(dt)
  end
end
