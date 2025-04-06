defmodule PhoenixEcto.HTMLTest do
  use ExUnit.Case, async: true

  import Ecto.Changeset
  import Phoenix.HTML
  import Phoenix.HTML.Form

  defp to_form(changeset, options \\ []) do
    Phoenix.HTML.FormData.to_form(changeset, options)
  end

  test "converts decimal to safe" do
    assert html_escape(Decimal.new("1.0")) == {:safe, "1.0"}
  end

  test "converts datetime to safe" do
    {:ok, t} = Time.new(0, 0, 0)
    assert html_escape(t) == {:safe, "00:00:00"}

    {:ok, d} = Date.new(2010, 4, 17)
    assert html_escape(d) == {:safe, "2010-04-17"}

    {:ok, dt} = NaiveDateTime.new(2010, 4, 17, 0, 0, 0)
    assert html_escape(dt) == {:safe, "2010-04-17T00:00:00"}
  end

  describe "to_form" do
    test "with changeset" do
      changeset =
        cast(%User{}, %{}, ~w()a)
        |> validate_length(:name, min: 3)

      f = to_form(changeset)
      assert f.id == "user"
      assert f.name == "user"
      assert f.impl == Phoenix.HTML.FormData.Ecto.Changeset
      assert f.source == changeset
      assert f.params == %{}
      assert f.hidden == []
      assert f.options == [method: "post"]
      assert f.action == nil
      assert f.source.action == nil
    end

    test "to_form :action option sets form action" do
      changeset =
        %User{}
        |> cast(%{}, ~w()a)
        |> validate_length(:name, min: 3)
        |> Map.replace!(:action, :validate)

      assert changeset.action == :validate
      f = to_form(changeset, action: :insert)
      assert f.action == :insert
    end

    test "to_form without :action option uses changeset action" do
      changeset =
        %User{}
        |> cast(%{}, ~w()a)
        |> validate_length(:name, min: 3)
        |> Map.put(:action, :insert)

      assert changeset.action == :insert
      f = to_form(changeset)
      assert f.action == :insert
      assert f.source.action == :insert
    end

    test "with loaded changeset" do
      changeset = cast(%User{__meta__: %{state: :loaded}, id: 13}, %{"foo" => "bar"}, ~w()a)

      f = to_form(changeset)
      assert f.id == "user"
      assert f.name == "user"
      assert f.source == changeset
      assert f.params == %{"foo" => "bar"}
      assert f.hidden == [id: 13]
      assert f.options == [method: "put"]
    end

    test "with custom options" do
      changeset = cast(%User{}, %{}, ~w()a)

      f = to_form(changeset, as: "another", multipart: true)
      assert f.id == "another"
      assert f.name == "another"
      assert f.source == changeset
      assert f.options == [method: "post", multipart: true]
    end

    test "form_for/4 with errors" do
      changeset =
        %User{}
        |> cast(%{"name" => "JV"}, ~w(name)a)
        |> validate_length(:name, min: 3)
        |> add_error(:score, "must be greater than %{count}", count: Decimal.new(18))

      f = to_form(changeset)
      assert f.errors == []

      changeset = %{changeset | action: :ignore}
      f = to_form(changeset)
      assert f.errors == []

      changeset = %{changeset | action: :insert}
      f = to_form(changeset)

      assert f.errors == [
               score: {"must be greater than %{count}", count: Decimal.new(18)},
               name:
                 {"should be at least %{count} character(s)",
                  count: 3, validation: :length, kind: :min, type: :string}
             ]
    end

    test "with schemaless changeset from a map" do
      changeset = cast({%{name: nil}, %{name: :string}}, %{"name" => "JV"}, ~w(name)a)

      f = to_form(changeset, as: "another")

      assert %Phoenix.HTML.FormField{
               id: "another_name",
               name: "another[name]",
               errors: [],
               field: :name,
               value: "JV"
             } = f[:name]

      assert %Phoenix.HTML.FormField{
               id: "another_other",
               name: "another[other]",
               errors: [],
               field: :other,
               value: nil
             } = f[:other]
    end

    test "with schemaless changeset from a struct" do
      changeset = cast({%SchemalessUser{}, %{name: :string}}, %{"name" => "JV"}, ~w(name)a)

      f = to_form(changeset)

      assert %Phoenix.HTML.FormField{
               id: "schemaless_user_name",
               name: "schemaless_user[name]",
               errors: [],
               field: :name,
               value: "JV"
             } = f[:name]
    end

    test "form_for/4 with id prefix id on inputs id" do
      changeset = cast(%User{}, %{"name" => "JV"}, ~w(name)a)
      f = to_form(changeset, id: "form_id")

      assert %Phoenix.HTML.FormField{
               id: "form_id_name",
               name: "user[name]",
               errors: [],
               field: :name,
               value: "JV"
             } = f[:name]
    end

    defmodule Custom do
      use Ecto.Schema

      schema "customs" do
        field :integer, :integer
        field :float, :float
        field :decimal, :decimal
        field :string, :string
        field :boolean, :boolean
        field :date, :date
        field :time, :time
        field :datetime, :naive_datetime
      end
    end

    test "input value" do
      changeset =
        %Custom{string: "string", integer: 321, float: 321}
        |> cast(%{float: 78.9, integer: 789}, ~w()a)
        |> put_change(:integer, 123)

      f = to_form(changeset)

      assert input_value(f, :integer) == 123
      assert input_value(f, :string) == "string"
      assert input_value(f, :float) == 78.9
    end

    test "input value rejects non-atom fields" do
      changeset =
        %Custom{string: "string", integer: 321, float: 321}
        |> cast(%{float: 78.9, integer: 789}, ~w()a)
        |> put_change(:integer, 123)

      msg = ~s(expected field to be an atom, got: "string")
      f = to_form(changeset)

      assert_raise ArgumentError, msg, fn ->
        input_value(f, "string")
      end
    end

    test "input validations" do
      changeset =
        cast(%Custom{}, %{}, ~w(integer string)a)
        |> validate_required([:integer, :string])
        |> validate_number(:integer, greater_than: 0, less_than: 100)
        |> validate_number(:float, greater_than_or_equal_to: 0)
        |> validate_length(:string, min: 0, max: 100)

      f = to_form(changeset)

      assert input_validations(f, :integer) == [required: true, step: 1, min: 1, max: 99]
      assert input_validations(f, :float) == [required: false, step: "any", min: 0]
      assert input_validations(f, :decimal) == [required: false]
      assert input_validations(f, :string) == [required: true, maxlength: 100, minlength: 0]
    end
  end
end
