defmodule PhoenixEcto.HTMLTest do
  use ExUnit.Case, async: true

  import Ecto.Changeset
  import Phoenix.HTML
  import Phoenix.HTML.Form

  test "converts decimal to safe" do
    assert html_escape(Decimal.new("1.0")) == {:safe, "1.0"}
  end

  test "converts datetime to safe" do
    t = %Ecto.Time{hour: 0, min: 0, sec: 0}
    assert html_escape(t) == {:safe, "00:00:00"}

    d = %Ecto.Date{year: 2010, month: 4, day: 17}
    assert html_escape(d) == {:safe, "2010-04-17"}

    dt = %Ecto.DateTime{year: 2010, month: 4, day: 17, hour: 0, min: 0, sec: 0}
    assert html_escape(dt) == {:safe, "2010-04-17 00:00:00"}
  end

  test "form_for/4 with new changeset" do
    changeset = cast(%User{}, :empty, ~w(), ~w())
                |> validate_length(:name, min: 3)

    form = safe_to_string(form_for(changeset, "/", fn f ->
      assert f.id == "user"
      assert f.name == "user"
      assert f.impl == Phoenix.HTML.FormData.Ecto.Changeset
      assert f.source == changeset
      assert f.params == %{}
      assert f.hidden == []
      "FROM FORM"
    end))

    assert form =~ ~s(<form accept-charset="UTF-8" action="/" method="post">)
    assert form =~ "FROM FORM"
  end

  test "form_for/4 with loaded changeset" do
    changeset = cast(%User{__meta__: %{state: :loaded}, id: 13},
                     %{"foo" => "bar"}, ~w(), ~w())

    form = safe_to_string(form_for(changeset, "/", fn f ->
      assert f.id == "user"
      assert f.name == "user"
      assert f.source == changeset
      assert f.params == %{"foo" => "bar"}
      assert f.hidden == [id: 13]
      "FROM FORM"
    end))

    assert form =~ ~s(<form accept-charset="UTF-8" action="/" method="post">)
    assert form =~ ~s(<input name="_method" type="hidden" value="put">)
    assert form =~ "FROM FORM"
    refute form =~ ~s(<input id="user_id" name="user[id]" type="hidden" value="13">)
  end

  test "form_for/4 with custom options" do
    changeset = cast(%User{}, :empty, ~w(), ~w())

    form = safe_to_string(form_for(changeset, "/", [as: "another", multipart: true], fn f ->
      assert f.id == "another"
      assert f.name == "another"
      assert f.source == changeset
      "FROM FORM"
    end))

    assert form =~ ~s(<form accept-charset="UTF-8" action="/" enctype="multipart/form-data" method="post">)
    assert form =~ "FROM FORM"
  end

  test "form_for/4 with errors" do
    changeset =
      %User{}
      |> cast(%{"name" => "JV"}, ~w(name), ~w())
      |> validate_length(:name, min: 3)
      |> add_error(:score, {"must be greater than %{count}", count: Decimal.new(18)})

    form = safe_to_string(form_for(changeset, "/", [as: "another", multipart: true], fn f ->
      assert f.errors == [score: "must be greater than 18",
                          name: "should be at least 3 characters"]
      "FROM FORM"
    end))

    assert form =~ ~s(<form accept-charset="UTF-8" action="/" enctype="multipart/form-data" method="post">)
    assert form =~ "FROM FORM"
  end

  test "form_for/4 with inputs" do
    changeset = cast(%User{}, %{"name" => "JV"}, ~w(name), ~w())

    form = safe_to_string(form_for(changeset, "/", [as: "another", multipart: true], fn f ->
      [text_input(f, :name), text_input(f, :other)]
    end))

    assert form =~ ~s(<input id="another_name" name="another[name]" type="text" value="JV">)
    assert form =~ ~s(<input id="another_other" name="another[other]" type="text">)
  end

  defmodule Custom do
    use Ecto.Schema

    schema "customs" do
      field :integer, :integer
      field :float, :float
      field :decimal, :decimal
      field :string,  :string
      field :boolean, :boolean
      field :date, Ecto.Date
      field :time, Ecto.Time
      field :datetime, Ecto.DateTime
    end
  end

  test "input types" do
    changeset = cast(%Custom{}, :empty, [], [])

    form_for(changeset, "/", fn f ->
      assert input_type(f, :integer) == :number_input
      assert input_type(f, :float) == :number_input
      assert input_type(f, :decimal) == :number_input
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
      cast(%Custom{}, :empty, ~w(integer string), ~w())
      |> validate_number(:integer, greater_than: 0, less_than: 100)
      |> validate_number(:float, greater_than_or_equal_to: 0)
      |> validate_length(:string, min: 0, max: 100)

    form_for(changeset, "/", fn f ->
      assert input_validations(f, :integer) == [required: true, step: 1, min: 1, max: 99]
      assert input_validations(f, :float)   == [required: false, step: "any", min: 0]
      assert input_validations(f, :decimal) == [required: false]
      assert input_validations(f, :string)  == [required: true, maxlength: 100, minlength: 0]
      ""
    end)
  end
end
