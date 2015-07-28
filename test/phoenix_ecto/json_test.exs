defmodule PhoenixEcto.JSONTest do
  use ExUnit.Case, async: true

  import Ecto.Changeset

  test "encodes datetimes" do
    time = %Ecto.Time{hour: 1, min: 2, sec: 3}
    assert Poison.encode!(time) == ~s("01:02:03")

    date = %Ecto.Date{year: 2010, month: 4, day: 17}
    assert Poison.encode!(date) == ~s("2010-04-17")

    dt = %Ecto.DateTime{year: 2010, month: 4, day: 17, hour: 0, min: 0, sec: 0}
    assert Poison.encode!(dt) == ~s("2010-04-17T00:00:00Z")
  end

  test "encodes decimal" do
    decimal = Decimal.new("1.0")
    assert Poison.encode!(decimal) == ~s("1.0")
  end

  test "encodes changeset errors" do
    changeset =
      cast(%User{}, %{age: "hi", title: "hi"}, ~w(name age title), ~w())
      |> validate_length(:title, min: 3)
      |> add_error(:name, "is taken")

    assert Poison.encode!(changeset) ==
           ~s({"title":["should be at least 3 characters"],"name":["is taken","can't be blank"],"age":["is invalid"]})
  end

  test "encodes changeset errors with embeds one error" do
    changeset =
      cast(%User{}, %{age: "hi", permalink: %{url: "hi"}}, ~w(age permalink), ~w())

    assert Poison.encode!(changeset) ==
           ~s({\"permalink\":{\"url\":[\"should be at least 3 characters\"]},\"age\":[\"is invalid\"]})
  end

  test "encodes changeset errors with embeds many errors" do
    changeset =
      cast(%User{}, %{age: "hi", permalinks: [%{url: "hi"}, %{url: "valid"}]}, ~w(age permalinks), ~w())

    assert Poison.encode!(changeset) ==
           ~s({\"permalinks\":[{\"url\":[\"should be at least 3 characters\"]},{}],\"age\":[\"is invalid\"]})
  end

  test "encodes changeset errors with decimal error" do
    changeset =
      cast(%User{}, %{score: Decimal.new(16.0)}, ~w(score), ~w())
      |> validate_number(:score, greater_than: Decimal.new(18))

    assert Poison.encode!(changeset) == ~s({"score":["must be greater than 18"]})
  end

  test "fails on association not loaded" do
    assert_raise RuntimeError,
                 ~r/cannot encode association :comments from User to JSON/, fn ->
      Poison.encode!(%User{}.comments)
    end
  end
end
