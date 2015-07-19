defmodule PhoenixEcto.JSONTest do
  use ExUnit.Case, async: true

  import Ecto.Changeset

  defmodule User do
    use Ecto.Model

    schema "users" do
      field :name
      field :title
      field :age, :integer
      has_many :comments, Comment
    end
  end

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

  test "fails on association not loaded" do
    assert_raise RuntimeError,
                 ~r/cannot encode association :comments from PhoenixEcto.JSONTest.User to JSON/, fn ->
      Poison.encode!(%User{}.comments)
    end
  end
end
