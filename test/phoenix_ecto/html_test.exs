defmodule PhoenixEcto.HTMLTest do
  use ExUnit.Case, async: true

  import Ecto.Changeset

  defmodule Permalink do
    use Ecto.Schema

    embedded_schema do
      field :url
    end

    def changeset(model, params) do
      model
      |> cast(params, ~w(url), ~w())
      |> validate_length(:url, min: 3)
    end
  end

  defmodule User do
    use Ecto.Schema

    schema "users" do
      field :name
      embeds_one :permalink, Permalink
      embeds_many :permalinks, Permalink
    end
  end

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
      assert f.source == changeset
      assert f.params == %{}
      assert f.hidden == []
      assert f.validations == [name: {:length, min: 3}]
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

    form = safe_to_string(form_for(changeset, "/", [name: "another", multipart: true], fn f ->
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

    form = safe_to_string(form_for(changeset, "/", [name: "another", multipart: true], fn f ->
      assert f.errors == [name: "should be at least 3 characters"]
      "FROM FORM"
    end))

    assert form =~ ~s(<form accept-charset="UTF-8" action="/" enctype="multipart/form-data" method="post">)
    assert form =~ "FROM FORM"
  end

  ## inputs_for one

  test "one: inputs_for/4 without default" do
    changeset = cast(%User{}, :empty, ~w(), ~w())

    contents =
      safe_inputs_for(changeset, :permalink, fn f ->
        assert f.errors == []
        assert f.validations == [url: {:length, min: 3}]
        text_input f, :url
      end)

    assert contents ==
           ~s(<input id="user_permalink_url" name="user[permalink][url]" type="text">)
  end

  test "one: inputs_for/4 with default" do
    changeset = cast(%User{}, :empty, ~w(), ~w())

    contents =
      safe_inputs_for(changeset, :permalink, [default: %Permalink{url: "default"}], fn f ->
        assert f.errors == []
        assert f.validations == [url: {:length, min: 3}]
        text_input f, :url
      end)

    assert contents ==
           ~s(<input id="user_permalink_url" name="user[permalink][url]" type="text" value="default">)
  end

  test "one: inputs_for/4 without default and model is present" do
    changeset = cast(%User{permalink: %Permalink{url: "model"}},
                     :empty, ~w(permalink), ~w())

    contents =
      safe_inputs_for(changeset, :permalink, fn f ->
        assert f.errors == []
        assert f.validations == [url: {:length, min: 3}]
        text_input f, :url
      end)

    assert contents ==
           ~s(<input id="user_permalink_url" name="user[permalink][url]" type="text" value="model">)
  end

  test "one: inputs_for/4 with default and model is present" do
    changeset = cast(%User{permalink: %Permalink{url: "model"}},
                     :empty, ~w(permalink), ~w())

    contents =
      safe_inputs_for(changeset, :permalink, [default: %Permalink{url: "default"}], fn f ->
        assert f.errors == []
        assert f.validations == [url: {:length, min: 3}]
        text_input f, :url
      end)

    assert contents ==
           ~s(<input id="user_permalink_url" name="user[permalink][url]" type="text" value="model">)
  end

  test "one: inputs_for/4 without default and params is present" do
    changeset = cast(%User{permalink: %Permalink{url: "model"}},
                     %{"permalink" => %{"url" => "ht"}}, ~w(permalink), ~w())

    contents =
      safe_inputs_for(changeset, :permalink, fn f ->
        assert f.errors == [url: "should be at least 3 characters"]
        assert f.validations == [url: {:length, min: 3}]
        text_input f, :url
      end)

    assert contents ==
           ~s(<input id="user_permalink_url" name="user[permalink][url]" type="text" value="ht">)
  end

  test "one: inputs_for/4 with default and params is present" do
    changeset = cast(%User{permalink: %Permalink{url: "model"}},
                     %{"permalink" => %{"url" => "ht"}}, ~w(permalink), ~w())

    contents =
      safe_inputs_for(changeset, :permalink, [default: %Permalink{url: "default"}], fn f ->
        assert f.errors == [url: "should be at least 3 characters"]
        assert f.validations == [url: {:length, min: 3}]
        text_input f, :url
      end)

    assert contents ==
           ~s(<input id="user_permalink_url" name="user[permalink][url]" type="text" value="ht">)
  end

  test "one: inputs_for/4 with custom id and name" do
    changeset = cast(%User{permalink: %Permalink{url: "model"}},
                     %{"permalink" => %{"url" => "given"}}, ~w(permalink), ~w())

    contents =
      safe_inputs_for(changeset, :permalink, [name: "foo", id: "bar"], fn f ->
        text_input f, :url
      end)

    assert contents ==
           ~s(<input id="bar_url" name="foo[url]" type="text" value="given">)
  end

  ## inputs_for many

  test "many: inputs_for/4 without default" do
    changeset = cast(%User{}, :empty, ~w(permalinks), ~w())

    contents =
      safe_inputs_for(changeset, :permalinks, fn f ->
        assert f.errors == []
        assert f.validations == [url: {:length, min: 3}]
        text_input f, :url
      end)

    assert contents == ""
  end

  test "many: inputs_for/4 with default" do
    changeset = cast(%User{}, :empty, ~w(permalinks), ~w())

    contents =
      safe_inputs_for(changeset, :permalinks, [default: [%Permalink{url: "default"}]], fn f ->
        assert f.errors == []
        assert f.validations == [url: {:length, min: 3}]
        text_input f, :url
      end)

    assert contents ==
           ~s(<input id="user_permalinks_0_url" name="user[permalinks][0][url]" type="text" value="default">)
  end

  test "many: inputs_for/4 without default and model is present" do
    changeset = cast(%User{permalinks: [%Permalink{url: "model1"}, %Permalink{url: "model2"}]},
                     :empty, ~w(permalinks), ~w())

    contents =
      safe_inputs_for(changeset, :permalinks, fn f ->
        assert f.errors == []
        assert f.validations == [url: {:length, min: 3}]
        text_input f, :url
      end)

    assert contents ==
      ~s(<input id="user_permalinks_0_url" name="user[permalinks][0][url]" type="text" value="model1">) <>
      ~s(<input id="user_permalinks_1_url" name="user[permalinks][1][url]" type="text" value="model2">)
  end

  test "many: inputs_for/4 with default and model is present" do
    changeset = cast(%User{permalinks: [%Permalink{url: "model1"}, %Permalink{url: "model2"}]},
                     :empty, ~w(permalinks), ~w())

    contents =
      safe_inputs_for(changeset, :permalinks, [default: [%Permalink{url: "default"}]], fn f ->
        assert f.errors == []
        assert f.validations == [url: {:length, min: 3}]
        text_input f, :url
      end)

    assert contents ==
      ~s(<input id="user_permalinks_0_url" name="user[permalinks][0][url]" type="text" value="model1">) <>
      ~s(<input id="user_permalinks_1_url" name="user[permalinks][1][url]" type="text" value="model2">)
  end

  test "many: inputs_for/4 with prepend, append and default" do
    default   = [%Permalink{url: "def1"}, %Permalink{url: "def2"}]
    changeset = cast(%User{}, :empty, ~w(permalinks), ~w())

    contents =
      safe_inputs_for(changeset, :permalinks, [default: default,
                        prepend: [%Permalink{url: "prepend"}],
                        append: [%Permalink{url: "append"}]], fn f ->
        assert f.errors == []
        assert f.validations == [url: {:length, min: 3}]
        text_input f, :url
      end)

    assert contents ==
      ~s(<input id="user_permalinks_0_url" name="user[permalinks][0][url]" type="text" value="prepend">) <>
      ~s(<input id="user_permalinks_1_url" name="user[permalinks][1][url]" type="text" value="def1">) <>
      ~s(<input id="user_permalinks_2_url" name="user[permalinks][2][url]" type="text" value="def2">) <>
      ~s(<input id="user_permalinks_3_url" name="user[permalinks][3][url]" type="text" value="append">)
  end

  test "many: inputs_for/4 with prepend and append with model" do
    permalinks = [%Permalink{id: "a", url: "model1"}, %Permalink{id: "b", url: "model2"}]
    changeset  = cast(%User{permalinks: permalinks}, :empty, ~w(permalinks), ~w())

    contents =
      safe_inputs_for(changeset, :permalinks,
                      [prepend: [%Permalink{url: "prepend"}],
                       append: [%Permalink{url: "append"}]], fn f ->
        assert f.errors == []
        assert f.validations == [url: {:length, min: 3}]
        text_input f, :url
      end)

    assert contents ==
      ~s(<input id="user_permalinks_0_url" name="user[permalinks][0][url]" type="text" value="prepend">) <>
      ~s(<input id="user_permalinks_1_id" name="user[permalinks][1][id]" type="hidden" value="a">) <>
      ~s(<input id="user_permalinks_1_url" name="user[permalinks][1][url]" type="text" value="model1">) <>
      ~s(<input id="user_permalinks_2_id" name="user[permalinks][2][id]" type="hidden" value="b">) <>
      ~s(<input id="user_permalinks_2_url" name="user[permalinks][2][url]" type="text" value="model2">) <>
      ~s(<input id="user_permalinks_3_url" name="user[permalinks][3][url]" type="text" value="append">)
  end

  test "many: inputs_for/4 with prepend and append with params" do
    permalinks = [%Permalink{id: "a", url: "model1"}, %Permalink{id: "b", url: "model2"}]
    changeset  = cast(%User{permalinks: permalinks},
                      %{"permalinks" => [%{"id" => "a", "url" => "h1"},
                                         %{"id" => "b", "url" => "h2"}]},
                      ~w(permalinks), ~w())

    contents =
      safe_inputs_for(changeset, :permalinks,
                      [prepend: [%Permalink{url: "prepend"}],
                       append: [%Permalink{url: "append"}]], fn f ->
        assert f.errors == [url: "should be at least 3 characters"]
        assert f.validations == [url: {:length, min: 3}]
        text_input f, :url
      end)

    assert contents ==
      ~s(<input id="user_permalinks_0_id" name="user[permalinks][0][id]" type="hidden" value="a">) <>
      ~s(<input id="user_permalinks_0_url" name="user[permalinks][0][url]" type="text" value="h1">) <>
      ~s(<input id="user_permalinks_1_id" name="user[permalinks][1][id]" type="hidden" value="b">) <>
      ~s(<input id="user_permalinks_1_url" name="user[permalinks][1][url]" type="text" value="h2">)
  end

  test "many: inputs_for/4 with custom id and name" do
    changeset = cast(%User{permalinks: [%Permalink{url: "model1"}, %Permalink{url: "model2"}]},
                     :empty, ~w(permalinks), ~w())

    contents =
      safe_inputs_for(changeset, :permalinks, [name: "foo", id: "bar"], fn f ->
        assert f.errors == []
        assert f.validations == [url: {:length, min: 3}]
        text_input f, :url
      end)

    assert contents ==
      ~s(<input id="bar_0_url" name="foo[0][url]" type="text" value="model1">) <>
      ~s(<input id="bar_1_url" name="foo[1][url]" type="text" value="model2">)
  end

  defp safe_inputs_for(changeset, field, opts \\ [], fun) do
    mark = "--PLACEHOLDER--"

    contents =
      safe_to_string form_for(changeset, "/", fn f ->
        html_escape [mark, inputs_for(f, field, opts, fun), mark]
      end)

    [_, inner, _] = String.split(contents, mark)
    inner
  end
end
