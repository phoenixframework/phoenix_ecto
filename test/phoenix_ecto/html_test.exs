defmodule PhoenixEcto.HTMLTest do
  use ExUnit.Case, async: true

  import Ecto.Changeset
  import Phoenix.HTML
  import Phoenix.HTML.Form

  defp safe_form_for(changeset, opts \\ [], function) do
    safe_to_string(form_for(changeset, "/", opts, function))
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
    assert html_escape(dt) == {:safe, "2010-04-17 00:00:00"}
  end

  test "form_for/3 with new changeset" do
    changeset = cast(%User{}, %{}, ~w()a)

    form = form_for(changeset, "/", [])
    assert %Phoenix.HTML.Form{} = form

    contents = form |> html_escape() |> safe_to_string()

    assert contents =~ ~s(<form action="/" method="post">)
  end

  test "form_for/3 with id prefix the form id in the input id" do
    changeset = cast(%User{}, %{}, ~w()a)

    form = form_for(changeset, "/", id: "form_id")

    form_content =
      form
      |> html_escape()
      |> safe_to_string()

    input_content =
      form
      |> text_input(:name)
      |> html_escape()
      |> safe_to_string()

    assert form_content =~ ~s(<form action="/" id="form_id" method="post">)
    assert input_content =~ ~s(<input id="form_id_name" name="user[name]" type="text">)
  end

  test "form_for/3 without id prefix the form name in the input id" do
    changeset = cast(%User{}, %{}, ~w()a)

    form = form_for(changeset, "/")

    contents =
      form
      |> text_input(:name)
      |> html_escape()
      |> safe_to_string()

    assert contents =~ ~s(<input id="user_name" name="user[name]" type="text">)
  end

  test "form_for/4 with new changeset" do
    changeset =
      cast(%User{}, %{}, ~w()a)
      |> validate_length(:name, min: 3)

    form =
      safe_form_for(changeset, fn f ->
        assert f.id == "user"
        assert f.name == "user"
        assert f.impl == Phoenix.HTML.FormData.Ecto.Changeset
        assert f.source == changeset
        assert f.params == %{}
        assert f.hidden == []
        "FROM FORM"
      end)

    assert form =~ ~s(<form action="/" method="post">)
    assert form =~ "FROM FORM"
  end

  test "form_for/4 with loaded changeset" do
    changeset = cast(%User{__meta__: %{state: :loaded}, id: 13}, %{"foo" => "bar"}, ~w()a)

    form =
      safe_form_for(changeset, fn f ->
        assert f.id == "user"
        assert f.name == "user"
        assert f.source == changeset
        assert f.params == %{"foo" => "bar"}
        assert f.hidden == [id: 13]
        "FROM FORM"
      end)

    assert form =~ ~s(<form action="/" method="post">)
    assert form =~ ~s(<input name="_method" type="hidden" value="put">)
    assert form =~ "FROM FORM"
    refute form =~ ~s(<input id="user_id" name="user[id]" type="hidden" value="13">)
  end

  test "form_for/4 with custom options" do
    changeset = cast(%User{}, %{}, ~w()a)

    form =
      safe_form_for(changeset, [as: "another", multipart: true], fn f ->
        assert f.id == "another"
        assert f.name == "another"
        assert f.source == changeset
        "FROM FORM"
      end)

    assert form =~
             ~s(<form action="/" enctype="multipart/form-data" method="post">)

    assert form =~ "FROM FORM"
  end

  test "form_for/4 with errors" do
    changeset =
      %User{}
      |> cast(%{"name" => "JV"}, ~w(name)a)
      |> validate_length(:name, min: 3)
      |> add_error(:score, "must be greater than %{count}", count: Decimal.new(18))

    safe_form_for(changeset, [as: "another", multipart: true], fn f ->
      assert f.errors == []
      "FROM FORM"
    end)

    changeset = %{changeset | action: :ignore}

    safe_form_for(changeset, [as: "another", multipart: true], fn f ->
      assert f.errors == []
      "FROM FORM"
    end)

    changeset = %{changeset | action: :insert}

    form =
      safe_form_for(changeset, [as: "another", multipart: true], fn f ->
        assert f.errors == [
                 score: {"must be greater than %{count}", count: Decimal.new(18)},
                 name:
                   {"should be at least %{count} character(s)",
                    count: 3, validation: :length, kind: :min}
               ]

        "FROM FORM"
      end)

    assert form =~
             ~s(<form action="/" enctype="multipart/form-data" method="post">)

    assert form =~ "FROM FORM"
  end

  test "form_for/4 with inputs" do
    changeset = cast(%User{}, %{"name" => "JV"}, ~w(name)a)

    form =
      safe_form_for(changeset, [as: "another", multipart: true], fn f ->
        [text_input(f, :name), text_input(f, :other)]
      end)

    assert form =~ ~s(<input id="another_name" name="another[name]" type="text" value="JV">)
    assert form =~ ~s(<input id="another_other" name="another[other]" type="text">)
  end

  describe "form_for/4 with schemaless changeset from a map" do
    test "with :as" do
      changeset = cast({%{name: nil}, %{name: :string}}, %{"name" => "JV"}, ~w(name)a)

      form =
        safe_form_for(changeset, [as: "another", multipart: true], fn f ->
          [text_input(f, :name), text_input(f, :other)]
        end)

      assert form =~ ~s(<input id="another_name" name="another[name]" type="text" value="JV">)
      assert form =~ ~s(<input id="another_other" name="another[other]" type="text">)
    end

    test "without :as" do
      changeset = cast({%{name: nil}, %{name: :string}}, %{"name" => "JV"}, ~w(name)a)

      form =
        safe_form_for(changeset, [multipart: true], fn f ->
          [text_input(f, :name), text_input(f, :other)]
        end)

      assert form =~ ~s(<input id="name" name="name" type="text" value="JV">)
      assert form =~ ~s(<input id="other" name="other" type="text">)
    end
  end

  describe "form_for/4 with schemaless changeset from a struct" do
    test "with :as" do
      changeset = cast({%SchemalessUser{}, %{name: :string}}, %{"name" => "JV"}, ~w(name)a)

      form =
        safe_form_for(changeset, [as: "another", multipart: true], fn f ->
          [text_input(f, :name), text_input(f, :other)]
        end)

      assert form =~ ~s(<input id="another_name" name="another[name]" type="text" value="JV">)
      assert form =~ ~s(<input id="another_other" name="another[other]" type="text">)
    end

    test "without :as" do
      changeset = cast({%SchemalessUser{}, %{name: :string}}, %{"name" => "JV"}, ~w(name)a)

      form =
        safe_form_for(changeset, [multipart: true], fn f ->
          [text_input(f, :name), text_input(f, :other)]
        end)

      assert form =~
               ~s(<input id="schemaless_user_name" name="schemaless_user[name]" type="text" value="JV">)

      assert form =~
               ~s(<input id="schemaless_user_other" name="schemaless_user[other]" type="text">)
    end
  end

  describe "form_for/4 with a map for changeset data" do
    test "with :as" do
      changeset = cast({%{}, %{name: :string}}, %{"name" => "JV"}, ~w(name)a)

      form =
        safe_form_for(changeset, [as: "some"], fn f ->
          [text_input(f, :name)]
        end)

      assert form =~ ~s(<input id="some_name" name="some[name]" type="text" value="JV">)
    end

    test "without :as" do
      changeset = cast({%{}, %{name: :string}}, %{"name" => "JV"}, ~w(name)a)

      form =
        safe_form_for(changeset, [], fn f ->
          [text_input(f, :name)]
        end)

      assert form =~ ~s(<input id="name" name="name" type="text" value="JV">)
    end
  end

  test "form_for/4 with Decimal type input field" do
    changeset =
      cast({%{}, %{price: :decimal}}, %{"price" => Decimal.new("0.000000000")}, ~w(price)a)

    form =
      safe_form_for(changeset, [as: "some"], fn f ->
        [number_input(f, :price)]
      end)

    assert form =~
             ~s(<input id="some_price" name="some[price]" type="number" value="0.000000000">)
  end

  test "form_for/4 with id prefix id on inputs id" do
    changeset = cast(%User{}, %{"name" => "JV"}, ~w(name)a)

    form =
      safe_form_for(changeset, [id: "form_id"], fn f ->
        text_input(f, :name)
      end)

    assert form =~ ~s(<input id="form_id_name" name="user[name]" type="text" value="JV">)
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

    safe_form_for(changeset, fn f ->
      assert input_value(f, :integer) == 123
      assert input_value(f, :string) == "string"
      assert input_value(f, :float) == 78.9
      ""
    end)
  end

  test "input types" do
    changeset = cast(%Custom{}, %{}, ~w()a)

    safe_form_for(changeset, fn f ->
      assert input_type(f, :integer) == :number_input
      # https://github.com/phoenixframework/phoenix_html/issues/279
      assert input_type(f, :float) == :text_input
      assert input_type(f, :decimal) == :text_input
      assert input_type(f, :string) == :text_input
      assert input_type(f, :boolean) == :checkbox
      assert input_type(f, :date) == :date_select
      assert input_type(f, :time) == :time_select
      assert input_type(f, :datetime) == :datetime_select
      ""
    end)
  end

  test "input validations" do
    changeset =
      cast(%Custom{}, %{}, ~w(integer string)a)
      |> validate_required([:integer, :string])
      |> validate_number(:integer, greater_than: 0, less_than: 100)
      |> validate_number(:float, greater_than_or_equal_to: 0)
      |> validate_length(:string, min: 0, max: 100)

    safe_form_for(changeset, fn f ->
      assert input_validations(f, :integer) == [required: true, step: 1, min: 1, max: 99]
      assert input_validations(f, :float) == [required: false, step: "any", min: 0]
      assert input_validations(f, :decimal) == [required: false]
      assert input_validations(f, :string) == [required: true, maxlength: 100, minlength: 0]
      ""
    end)
  end
end
