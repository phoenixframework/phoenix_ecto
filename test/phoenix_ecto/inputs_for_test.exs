defmodule PhoenixEcto.InputsForTest do
  use ExUnit.Case, async: true

  import Ecto.Changeset
  import Phoenix.HTML
  import Phoenix.HTML.Form

  ## inputs_for has_one

  test "has one: inputs_for/4 without default" do
    changeset = cast(%User{}, :empty, ~w(), ~w())

    contents =
      safe_inputs_for(changeset, :comment, fn f ->
        assert f.impl == Phoenix.HTML.FormData.Ecto.Changeset
        assert f.errors == []
        assert f.source.validations == [body: {:length, min: 3}]
        text_input f, :body
      end)

    assert contents ==
           ~s(<input id="user_comment_body" name="user[comment][body]" type="text">)
  end

  test "has one: inputs_for/4 with default" do
    changeset = cast(%User{}, :empty, ~w(), ~w())

    contents =
      safe_inputs_for(changeset, :comment, [default: %Comment{body: "default"}], fn f ->
        assert f.errors == []
        assert f.source.validations == [body: {:length, min: 3}]
        text_input f, :body
      end)

    assert contents ==
           ~s(<input id="user_comment_body" name="user[comment][body]" type="text" value="default">)
  end

  test "has one: inputs_for/4 without default and model is present" do
    changeset = cast(%User{comment: %Comment{body: "model"}},
                     :empty, ~w(comment), ~w())

    contents =
      safe_inputs_for(changeset, :comment, fn f ->
        assert f.errors == []
        assert f.source.validations == [body: {:length, min: 3}]
        text_input f, :body
      end)

    assert contents ==
           ~s(<input id="user_comment_body" name="user[comment][body]" type="text" value="model">)
  end

  test "has one: inputs_for/4 with default and model is present" do
    changeset = cast(%User{comment: %Comment{body: "model"}},
                     :empty, ~w(comment), ~w())

    contents =
      safe_inputs_for(changeset, :comment, [default: %Comment{body: "default"}], fn f ->
        assert f.errors == []
        assert f.source.validations == [body: {:length, min: 3}]
        text_input f, :body
      end)

    assert contents ==
           ~s(<input id="user_comment_body" name="user[comment][body]" type="text" value="model">)
  end

  test "has one: inputs_for/4 without default and params is present" do
    changeset = cast(%User{comment: %Comment{body: "model"}},
                     %{"comment" => %{"body" => "ht"}}, ~w(comment), ~w())

    contents =
      safe_inputs_for(changeset, :comment, fn f ->
        assert f.errors == [body: "should be at least 3 characters"]
        assert f.source.validations == [body: {:length, min: 3}]
        text_input f, :body
      end)

    assert contents ==
           ~s(<input id="user_comment_body" name="user[comment][body]" type="text" value="ht">)
  end

  test "has one: inputs_for/4 with default and params is present" do
    changeset = cast(%User{comment: %Comment{body: "model"}},
                     %{"comment" => %{"body" => "ht"}}, ~w(comment), ~w())

    contents =
      safe_inputs_for(changeset, :comment, [default: %Comment{body: "default"}], fn f ->
        assert f.errors == [body: "should be at least 3 characters"]
        assert f.source.validations == [body: {:length, min: 3}]
        text_input f, :body
      end)

    assert contents ==
           ~s(<input id="user_comment_body" name="user[comment][body]" type="text" value="ht">)
  end

  test "has one: inputs_for/4 with custom id and name" do
    changeset = cast(%User{comment: %Comment{body: "model"}},
                     %{"comment" => %{"body" => "given"}}, ~w(comment), ~w())

    contents =
      safe_inputs_for(changeset, :comment, [name: "foo", id: "bar"], fn f ->
        text_input f, :body
      end)

    assert contents ==
           ~s(<input id="bar_body" name="foo[body]" type="text" value="given">)
  end

  ## inputs_for has_many

  test "has many: inputs_for/4 without default" do
    changeset = cast(%User{}, :empty, ~w(comments), ~w())

    contents =
      safe_inputs_for(changeset, :comments, fn f ->
        text_input f, :body
      end)

    assert contents == ""
  end

  test "has many: inputs_for/4 with default" do
    changeset = cast(%User{}, :empty, ~w(comments), ~w())

    contents =
      safe_inputs_for(changeset, :comments, [default: [%Comment{body: "default"}]], fn f ->
        assert f.impl == Phoenix.HTML.FormData.Ecto.Changeset
        assert f.index == 0
        assert f.errors == []
        assert f.source.validations == [body: {:length, min: 3}]
        text_input f, :body
      end)

    assert contents ==
           ~s(<input id="user_comments_0_body" name="user[comments][0][body]" type="text" value="default">)
  end

  test "has many: inputs_for/4 without default and model is present" do
    changeset = cast(%User{comments: [%Comment{body: "model1"}, %Comment{body: "model2"}]},
                     :empty, ~w(comments), ~w())

    contents =
      safe_inputs_for(changeset, :comments, fn f ->
        assert f.impl == Phoenix.HTML.FormData.Ecto.Changeset
        assert f.index in [0, 1]
        assert f.errors == []
        assert f.source.validations == [body: {:length, min: 3}]
        text_input f, :body
      end)

    assert contents ==
      ~s(<input id="user_comments_0_body" name="user[comments][0][body]" type="text" value="model1">) <>
      ~s(<input id="user_comments_1_body" name="user[comments][1][body]" type="text" value="model2">)
  end

  test "has many: inputs_for/4 with default and model is present" do
    changeset = cast(%User{comments: [%Comment{body: "model1"}, %Comment{body: "model2"}]},
                     :empty, ~w(comments), ~w())

    contents =
      safe_inputs_for(changeset, :comments, [default: [%Comment{body: "default"}]], fn f ->
        assert f.errors == []
        assert f.source.validations == [body: {:length, min: 3}]
        text_input f, :body
      end)

    assert contents ==
      ~s(<input id="user_comments_0_body" name="user[comments][0][body]" type="text" value="model1">) <>
      ~s(<input id="user_comments_1_body" name="user[comments][1][body]" type="text" value="model2">)
  end

  test "has many: inputs_for/4 with prepend, append and default" do
    default   = [%Comment{body: "def1"}, %Comment{body: "def2"}]
    changeset = cast(%User{}, :empty, ~w(comments), ~w())

    contents =
      safe_inputs_for(changeset, :comments, [default: default,
                        prepend: [%Comment{body: "prepend"}],
                        append: [%Comment{body: "append"}]], fn f ->
        assert f.errors == []
        assert f.source.validations == [body: {:length, min: 3}]
        text_input f, :body
      end)

    assert contents ==
      ~s(<input id="user_comments_0_body" name="user[comments][0][body]" type="text" value="prepend">) <>
      ~s(<input id="user_comments_1_body" name="user[comments][1][body]" type="text" value="def1">) <>
      ~s(<input id="user_comments_2_body" name="user[comments][2][body]" type="text" value="def2">) <>
      ~s(<input id="user_comments_3_body" name="user[comments][3][body]" type="text" value="append">)
  end

  test "has many: inputs_for/4 with prepend and append with model" do
    comments = [%Comment{id: "a", body: "model1"}, %Comment{id: "b", body: "model2"}]
    changeset = cast(%User{comments: comments}, :empty, ~w(comments), ~w())

    contents =
      safe_inputs_for(changeset, :comments,
                      [prepend: [%Comment{body: "prepend"}],
                       append: [%Comment{body: "append"}]], fn f ->
        assert f.errors == []
        assert f.source.validations == [body: {:length, min: 3}]
        text_input f, :body
      end)

    assert contents ==
      ~s(<input id="user_comments_0_body" name="user[comments][0][body]" type="text" value="prepend">) <>
      ~s(<input id="user_comments_1_id" name="user[comments][1][id]" type="hidden" value="a">) <>
      ~s(<input id="user_comments_1_body" name="user[comments][1][body]" type="text" value="model1">) <>
      ~s(<input id="user_comments_2_id" name="user[comments][2][id]" type="hidden" value="b">) <>
      ~s(<input id="user_comments_2_body" name="user[comments][2][body]" type="text" value="model2">) <>
      ~s(<input id="user_comments_3_body" name="user[comments][3][body]" type="text" value="append">)
  end

  test "has many: inputs_for/4 with prepend and append with params" do
    comments = [%Comment{id: 1, body: "model1"}, %Comment{id: 2, body: "model2"}]
    changeset  = cast(%User{comments: comments},
                      %{"comments" => [%{"id" => "1", "body" => "h1"},
                                       %{"id" => "2", "body" => "h2"}]},
                      ~w(comments), ~w())

    contents =
      safe_inputs_for(changeset, :comments,
                      [prepend: [%Comment{body: "prepend"}],
                       append: [%Comment{body: "append"}]], fn f ->
        assert f.errors == [body: "should be at least 3 characters"]
        assert f.source.validations == [body: {:length, min: 3}]
        text_input f, :body
      end)

    assert contents ==
      ~s(<input id="user_comments_0_id" name="user[comments][0][id]" type="hidden" value="1">) <>
      ~s(<input id="user_comments_0_body" name="user[comments][0][body]" type="text" value="h1">) <>
      ~s(<input id="user_comments_1_id" name="user[comments][1][id]" type="hidden" value="2">) <>
      ~s(<input id="user_comments_1_body" name="user[comments][1][body]" type="text" value="h2">)
  end

  test "has many: inputs_for/4 with custom id and name" do
    changeset = cast(%User{comments: [%Comment{body: "model1"}, %Comment{body: "model2"}]},
                     :empty, ~w(comments), ~w())

    contents =
      safe_inputs_for(changeset, :comments, [name: "foo", id: "bar"], fn f ->
        assert f.errors == []
        assert f.source.validations == [body: {:length, min: 3}]
        text_input f, :body
      end)

    assert contents ==
      ~s(<input id="bar_0_body" name="foo[0][body]" type="text" value="model1">) <>
      ~s(<input id="bar_1_body" name="foo[1][body]" type="text" value="model2">)
  end

  ## inputs_for embeds one

  test "embeds one: inputs_for/4 without default" do
    changeset = cast(%User{}, :empty, ~w(), ~w())

    contents =
      safe_inputs_for(changeset, :permalink, fn f ->
        assert f.impl == Phoenix.HTML.FormData.Ecto.Changeset
        assert f.errors == []
        assert f.source.validations == [url: {:length, min: 3}]
        text_input f, :url
      end)

    assert contents ==
           ~s(<input id="user_permalink_url" name="user[permalink][url]" type="text">)
  end

  test "embeds one: inputs_for/4 with default" do
    changeset = cast(%User{}, :empty, ~w(), ~w())

    contents =
      safe_inputs_for(changeset, :permalink, [default: %Permalink{url: "default"}], fn f ->
        assert f.errors == []
        assert f.source.validations == [url: {:length, min: 3}]
        text_input f, :url
      end)

    assert contents ==
           ~s(<input id="user_permalink_url" name="user[permalink][url]" type="text" value="default">)
  end

  test "embeds one: inputs_for/4 without default and model is present" do
    changeset = cast(%User{permalink: %Permalink{url: "model"}},
                     :empty, ~w(permalink), ~w())

    contents =
      safe_inputs_for(changeset, :permalink, fn f ->
        assert f.errors == []
        assert f.source.validations == [url: {:length, min: 3}]
        text_input f, :url
      end)

    assert contents ==
           ~s(<input id="user_permalink_url" name="user[permalink][url]" type="text" value="model">)
  end

  test "embeds one: inputs_for/4 with default and model is present" do
    changeset = cast(%User{permalink: %Permalink{url: "model"}},
                     :empty, ~w(permalink), ~w())

    contents =
      safe_inputs_for(changeset, :permalink, [default: %Permalink{url: "default"}], fn f ->
        assert f.errors == []
        assert f.source.validations == [url: {:length, min: 3}]
        text_input f, :url
      end)

    assert contents ==
           ~s(<input id="user_permalink_url" name="user[permalink][url]" type="text" value="model">)
  end

  test "embeds one: inputs_for/4 without default and params is present" do
    changeset = cast(%User{permalink: %Permalink{url: "model"}},
                     %{"permalink" => %{"url" => "ht"}}, ~w(permalink), ~w())

    contents =
      safe_inputs_for(changeset, :permalink, fn f ->
        assert f.errors == [url: "should be at least 3 characters"]
        assert f.source.validations == [url: {:length, min: 3}]
        text_input f, :url
      end)

    assert contents ==
           ~s(<input id="user_permalink_url" name="user[permalink][url]" type="text" value="ht">)
  end

  test "embeds one: inputs_for/4 with default and params is present" do
    changeset = cast(%User{permalink: %Permalink{url: "model"}},
                     %{"permalink" => %{"url" => "ht"}}, ~w(permalink), ~w())

    contents =
      safe_inputs_for(changeset, :permalink, [default: %Permalink{url: "default"}], fn f ->
        assert f.errors == [url: "should be at least 3 characters"]
        assert f.source.validations == [url: {:length, min: 3}]
        text_input f, :url
      end)

    assert contents ==
           ~s(<input id="user_permalink_url" name="user[permalink][url]" type="text" value="ht">)
  end

  test "embeds one: inputs_for/4 with custom id and name" do
    changeset = cast(%User{permalink: %Permalink{url: "model"}},
                     %{"permalink" => %{"url" => "given"}}, ~w(permalink), ~w())

    contents =
      safe_inputs_for(changeset, :permalink, [name: "foo", id: "bar"], fn f ->
        text_input f, :url
      end)

    assert contents ==
           ~s(<input id="bar_url" name="foo[url]" type="text" value="given">)
  end

  ## inputs_for embeds many

  test "embeds many: inputs_for/4 without default" do
    changeset = cast(%User{}, :empty, ~w(permalinks), ~w())

    contents =
      safe_inputs_for(changeset, :permalinks, fn f ->
        text_input f, :url
      end)

    assert contents == ""
  end

  test "embeds many: inputs_for/4 with default" do
    changeset = cast(%User{}, :empty, ~w(permalinks), ~w())

    contents =
      safe_inputs_for(changeset, :permalinks, [default: [%Permalink{url: "default"}]], fn f ->
        assert f.impl == Phoenix.HTML.FormData.Ecto.Changeset
        assert f.index == 0
        assert f.errors == []
        assert f.source.validations == [url: {:length, min: 3}]
        text_input f, :url
      end)

    assert contents ==
           ~s(<input id="user_permalinks_0_url" name="user[permalinks][0][url]" type="text" value="default">)
  end

  test "embeds many: inputs_for/4 without default and model is present" do
    changeset = cast(%User{permalinks: [%Permalink{url: "model1"}, %Permalink{url: "model2"}]},
                     :empty, ~w(permalinks), ~w())

    contents =
      safe_inputs_for(changeset, :permalinks, fn f ->
        assert f.impl == Phoenix.HTML.FormData.Ecto.Changeset
        assert f.index in [0, 1]
        assert f.errors == []
        assert f.source.validations == [url: {:length, min: 3}]
        text_input f, :url
      end)

    assert contents ==
      ~s(<input id="user_permalinks_0_url" name="user[permalinks][0][url]" type="text" value="model1">) <>
      ~s(<input id="user_permalinks_1_url" name="user[permalinks][1][url]" type="text" value="model2">)
  end

  test "embeds many: inputs_for/4 with default and model is present" do
    changeset = cast(%User{permalinks: [%Permalink{url: "model1"}, %Permalink{url: "model2"}]},
                     :empty, ~w(permalinks), ~w())

    contents =
      safe_inputs_for(changeset, :permalinks, [default: [%Permalink{url: "default"}]], fn f ->
        assert f.errors == []
        assert f.source.validations == [url: {:length, min: 3}]
        text_input f, :url
      end)

    assert contents ==
      ~s(<input id="user_permalinks_0_url" name="user[permalinks][0][url]" type="text" value="model1">) <>
      ~s(<input id="user_permalinks_1_url" name="user[permalinks][1][url]" type="text" value="model2">)
  end

  test "embeds many: inputs_for/4 with prepend, append and default" do
    default   = [%Permalink{url: "def1"}, %Permalink{url: "def2"}]
    changeset = cast(%User{}, :empty, ~w(permalinks), ~w())

    contents =
      safe_inputs_for(changeset, :permalinks, [default: default,
                        prepend: [%Permalink{url: "prepend"}],
                        append: [%Permalink{url: "append"}]], fn f ->
        assert f.errors == []
        assert f.source.validations == [url: {:length, min: 3}]
        text_input f, :url
      end)

    assert contents ==
      ~s(<input id="user_permalinks_0_url" name="user[permalinks][0][url]" type="text" value="prepend">) <>
      ~s(<input id="user_permalinks_1_url" name="user[permalinks][1][url]" type="text" value="def1">) <>
      ~s(<input id="user_permalinks_2_url" name="user[permalinks][2][url]" type="text" value="def2">) <>
      ~s(<input id="user_permalinks_3_url" name="user[permalinks][3][url]" type="text" value="append">)
  end

  test "embeds many: inputs_for/4 with prepend and append with model" do
    permalinks = [%Permalink{id: "a", url: "model1"}, %Permalink{id: "b", url: "model2"}]
    changeset  = cast(%User{permalinks: permalinks}, :empty, ~w(permalinks), ~w())

    contents =
      safe_inputs_for(changeset, :permalinks,
                      [prepend: [%Permalink{url: "prepend"}],
                       append: [%Permalink{url: "append"}]], fn f ->
        assert f.errors == []
        assert f.source.validations == [url: {:length, min: 3}]
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

  test "embeds many: inputs_for/4 with prepend and append with params" do
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
        assert f.source.validations == [url: {:length, min: 3}]
        text_input f, :url
      end)

    assert contents ==
      ~s(<input id="user_permalinks_0_id" name="user[permalinks][0][id]" type="hidden" value="a">) <>
      ~s(<input id="user_permalinks_0_url" name="user[permalinks][0][url]" type="text" value="h1">) <>
      ~s(<input id="user_permalinks_1_id" name="user[permalinks][1][id]" type="hidden" value="b">) <>
      ~s(<input id="user_permalinks_1_url" name="user[permalinks][1][url]" type="text" value="h2">)
  end

  test "embeds many: inputs_for/4 with custom id and name" do
    changeset = cast(%User{permalinks: [%Permalink{url: "model1"}, %Permalink{url: "model2"}]},
                     :empty, ~w(permalinks), ~w())

    contents =
      safe_inputs_for(changeset, :permalinks, [name: "foo", id: "bar"], fn f ->
        assert f.errors == []
        assert f.source.validations == [url: {:length, min: 3}]
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
