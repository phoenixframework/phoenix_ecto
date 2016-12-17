defmodule PhoenixEcto.InputsForTest do
  use ExUnit.Case, async: true

  import Ecto.Changeset
  import Phoenix.HTML
  import Phoenix.HTML.Form

  ## inputs_for has_one

  test "has one: inputs_for/4" do
    changeset =
      %User{}
      |> cast(%{}, ~w())
      |> cast_assoc(:comment)

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


  test "has one: inputs_for/4 with data" do
    changeset =
      %User{comment: %Comment{body: "data"}}
      |> cast(%{}, ~w())
      |> cast_assoc(:comment)

    contents =
      safe_inputs_for(changeset, :comment, fn f ->
        assert f.errors == []
        assert f.source.validations == [body: {:length, min: 3}]
        text_input f, :body
      end)

    assert contents ==
           ~s(<input id="user_comment_body" name="user[comment][body]" type="text" value="data">)
  end

  test "has one: inputs_for/4 with params" do
    changeset =
      %User{comment: %Comment{body: "data"}}
      |> cast(%{"comment" => %{"body" => "ht"}}, ~w())
      |> cast_assoc(:comment)

    contents =
      safe_inputs_for(changeset, :comment, fn f ->
        assert f.errors == []
        assert f.source.validations == [body: {:length, min: 3}]
        text_input f, :body
      end)

    assert contents ==
           ~s(<input id="user_comment_body" name="user[comment][body]" type="text" value="ht">)

    contents =
      safe_inputs_for(Map.put(changeset, :action, :insert), :comment, fn f ->
        assert f.errors == [body: {"should be at least %{count} character(s)", count: 3, validation: :length, min: 3}]
        assert f.source.validations == [body: {:length, min: 3}]
        text_input f, :body
      end)

    assert contents ==
           ~s(<input id="user_comment_body" name="user[comment][body]" type="text" value="ht">)
  end

  test "has one: inputs_for/4 with custom id and name" do
    changeset =
      %User{comment: %Comment{body: "data"}}
      |> cast(%{"comment" => %{"body" => "given"}}, ~w())
      |> cast_assoc(:comment)

    contents =
      safe_inputs_for(changeset, :comment, [as: "foo", id: "bar"], fn f ->
        text_input f, :body
      end)

    assert contents ==
           ~s(<input id="bar_body" name="foo[body]" type="text" value="given">)
  end

  test "has one: inputs_for/4 and replaced changesets" do
    changeset =
      %User{comment: %Comment{id: 1}}
      |> cast(%{"comment" => nil}, ~w())
      |> cast_assoc(:comment)

    input = ~s(<input id="user_comment_body" name="user[comment][body]" type="text">)

    refute safe_inputs_for(changeset, :comment, [], fn f ->
      text_input f, :body
    end) =~ input
  end

  ## inputs_for has_many

  test "has many: inputs_for/4" do
    changeset =
      %User{}
      |> cast(%{}, ~w())
      |> cast_assoc(:comments)

    contents =
      safe_inputs_for(changeset, :comments, fn f ->
        text_input f, :body
      end)

    assert contents == ""
  end

  test "has many: inputs_for/4 with data" do
    changeset =
      %User{comments: [%Comment{body: "data1"}, %Comment{body: "data2"}]}
      |> cast(%{}, ~w())
      |> cast_assoc(:comments)

    contents =
      safe_inputs_for(changeset, :comments, fn f ->
        assert f.impl == Phoenix.HTML.FormData.Ecto.Changeset
        assert f.index in [0, 1]
        assert f.errors == []
        assert f.source.validations == [body: {:length, min: 3}]
        text_input f, :body
      end)

    assert contents ==
      ~s(<input id="user_comments_0_body" name="user[comments][0][body]" type="text" value="data1">) <>
      ~s(<input id="user_comments_1_body" name="user[comments][1][body]" type="text" value="data2">)
  end

  test "has many: inputs_for/4 with prepend and append" do
    changeset =
      %User{comments: [%Comment{body: "def1"}, %Comment{body: "def2"}]}
      |> cast(%{}, ~w())
      |> cast_assoc(:comments)
      |> Map.put(:action, :insert)

    contents =
      safe_inputs_for(changeset, :comments, [
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

  test "has many: inputs_for/4 with prepend and append with data" do
    changeset =
      %User{comments: [%Comment{id: "a", body: "data1"}, %Comment{id: "b", body: "data2"}]}
      |> cast(%{}, ~w())
      |> cast_assoc(:comments)
      |> Map.put(:action, :insert)

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
      ~s(<input id="user_comments_1_body" name="user[comments][1][body]" type="text" value="data1">) <>
      ~s(<input id="user_comments_2_id" name="user[comments][2][id]" type="hidden" value="b">) <>
      ~s(<input id="user_comments_2_body" name="user[comments][2][body]" type="text" value="data2">) <>
      ~s(<input id="user_comments_3_body" name="user[comments][3][body]" type="text" value="append">)
  end

  test "has many: inputs_for/4 with prepend and append with params" do
    comments = [%Comment{id: 1, body: "data1"}, %Comment{id: 2, body: "data2"}]
    changeset =
      %User{comments: comments}
      |> cast(%{"comments" => [%{"id" => "1", "body" => "h1"},
                               %{"id" => "2", "body" => "h2"}]}, ~w())
      |> cast_assoc(:comments)
      |> Map.put(:action, :insert)

    contents =
      safe_inputs_for(changeset, :comments,
                      [prepend: [%Comment{body: "prepend"}],
                       append: [%Comment{body: "append"}]], fn f ->
        assert f.errors == [body: {"should be at least %{count} character(s)", count: 3, validation: :length, min: 3}]
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
    changeset =
      %User{comments: [%Comment{body: "data1"}, %Comment{body: "data2"}]}
      |> cast(%{}, ~w())
      |> cast_assoc(:comments)

    contents =
      safe_inputs_for(changeset, :comments, [as: "foo", id: "bar"], fn f ->
        assert f.errors == []
        assert f.source.validations == [body: {:length, min: 3}]
        text_input f, :body
      end)

    assert contents ==
      ~s(<input id="bar_0_body" name="foo[0][body]" type="text" value="data1">) <>
      ~s(<input id="bar_1_body" name="foo[1][body]" type="text" value="data2">)
  end

  test "has many: inputs_for/4 with replaced changesets" do
    changeset =
      %User{comments: [%Comment{id: 1, body: "data1"}, %Comment{id: 2, body: "data2"}]}
      |> cast(%{"comments" => []}, ~w())
      |> cast_assoc(:comments)

    input = ~r(<input id="user_comments_0_body".*<input id="user_comments_1_body")

    refute safe_inputs_for(changeset, :comments, [], fn f ->
      text_input f, :body
    end) =~ input
  end

  ## inputs_for embeds one

  test "embeds one: inputs_for/4" do
    changeset =
      %User{}
      |> cast(%{}, ~w())
      |> cast_embed(:permalink)

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

  test "embeds one: inputs_for/4 with data" do
    changeset =
      %User{permalink: %Permalink{url: "data"}}
      |> cast(%{}, ~w())
      |> cast_embed(:permalink)

    contents =
      safe_inputs_for(changeset, :permalink, fn f ->
        assert f.errors == []
        assert f.source.validations == [url: {:length, min: 3}]
        text_input f, :url
      end)

    assert contents ==
           ~s(<input id="user_permalink_url" name="user[permalink][url]" type="text" value="data">)
  end

  test "embeds one: inputs_for/4 with params" do
    changeset =
      %User{permalink: %Permalink{url: "data"}}
      |> cast(%{"permalink" => %{"url" => "ht"}}, ~w())
      |> cast_embed(:permalink)

    contents =
      safe_inputs_for(changeset, :permalink, fn f ->
        assert f.errors == []
        assert f.source.validations == [url: {:length, min: 3}]
        text_input f, :url
      end)

    assert contents ==
           ~s(<input id="user_permalink_url" name="user[permalink][url]" type="text" value="ht">)

    contents =
      safe_inputs_for(Map.put(changeset, :action, :insert), :permalink, fn f ->
        assert f.errors == [url: {"should be at least %{count} character(s)", count: 3, validation: :length, min: 3}]
        assert f.source.validations == [url: {:length, min: 3}]
        text_input f, :url
      end)

    assert contents ==
           ~s(<input id="user_permalink_url" name="user[permalink][url]" type="text" value="ht">)
  end

  test "embeds one: inputs_for/4 with custom id and name" do
    changeset =
      %User{permalink: %Permalink{url: "data"}}
      |> cast(%{"permalink" => %{"url" => "given"}}, ~w())
      |> cast_embed(:permalink)

    contents =
      safe_inputs_for(changeset, :permalink, [as: "foo", id: "bar"], fn f ->
        text_input f, :url
      end)

    assert contents ==
           ~s(<input id="bar_url" name="foo[url]" type="text" value="given">)
  end

  test "embeds one: inputs_for/4 and replaced changesets" do
    changeset =
      %User{permalink: %Permalink{id: 1}}
      |> cast(%{"permalink" => nil}, ~w())
      |> cast_embed(:permalink)

    input = ~s(<input id="user_permalink_url" name="user[permalink][url]" type="text">)

    refute safe_inputs_for(changeset, :permalink, [], fn f ->
      text_input f, :url
    end) =~ input
  end

  ## inputs_for embeds many

  test "embeds many: inputs_for/4" do
    changeset =
      %User{}
      |> cast(%{}, ~w())
      |> cast_embed(:permalinks)

    contents =
      safe_inputs_for(changeset, :permalinks, fn f ->
        text_input f, :url
      end)

    assert contents == ""
  end

  test "embeds many: inputs_for/4 with data" do
    changeset =
      %User{permalinks: [%Permalink{url: "data1"}, %Permalink{url: "data2"}]}
      |> cast(%{}, ~w())
      |> cast_embed(:permalinks)

    contents =
      safe_inputs_for(changeset, :permalinks, fn f ->
        assert f.impl == Phoenix.HTML.FormData.Ecto.Changeset
        assert f.index in [0, 1]
        assert f.errors == []
        assert f.source.validations == [url: {:length, min: 3}]
        text_input f, :url
      end)

    assert contents ==
      ~s(<input id="user_permalinks_0_url" name="user[permalinks][0][url]" type="text" value="data1">) <>
      ~s(<input id="user_permalinks_1_url" name="user[permalinks][1][url]" type="text" value="data2">)
  end

  test "embeds many: inputs_for/4 with prepend and append" do
    changeset =
      %User{permalinks: [%Permalink{url: "def1"}, %Permalink{url: "def2"}]}
      |> cast(%{}, ~w())
      |> cast_embed(:permalinks)
      |> Map.put(:action, :insert)

    contents =
      safe_inputs_for(changeset, :permalinks, [
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

  test "embeds many: inputs_for/4 with prepend and append with data" do
    changeset =
      %User{permalinks: [%Permalink{id: "a", url: "data1"}, %Permalink{id: "b", url: "data2"}]}
      |> cast(%{}, ~w())
      |> cast_embed(:permalinks)
      |> Map.put(:action, :insert)

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
      ~s(<input id="user_permalinks_1_url" name="user[permalinks][1][url]" type="text" value="data1">) <>
      ~s(<input id="user_permalinks_2_id" name="user[permalinks][2][id]" type="hidden" value="b">) <>
      ~s(<input id="user_permalinks_2_url" name="user[permalinks][2][url]" type="text" value="data2">) <>
      ~s(<input id="user_permalinks_3_url" name="user[permalinks][3][url]" type="text" value="append">)
  end

  test "embeds many: inputs_for/4 with prepend and append with params" do
    permalinks = [%Permalink{id: "a", url: "data1"}, %Permalink{id: "b", url: "data2"}]
    changeset  =
      %User{permalinks: permalinks}
      |> cast(%{"permalinks" => [%{"id" => "a", "url" => "h1"},
                                 %{"id" => "b", "url" => "h2"}]}, ~w())
      |> cast_embed(:permalinks)
      |> Map.put(:action, :insert)

    contents =
      safe_inputs_for(changeset, :permalinks,
                      [prepend: [%Permalink{url: "prepend"}],
                       append: [%Permalink{url: "append"}]], fn f ->
        assert f.errors == [url: {"should be at least %{count} character(s)", [count: 3, validation: :length, min: 3]}]
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
    changeset =
      %User{permalinks: [%Permalink{url: "data1"}, %Permalink{url: "data2"}]}
      |> cast(%{}, ~w())
      |> cast_embed(:permalinks)

    contents =
      safe_inputs_for(changeset, :permalinks, [as: "foo", id: "bar"], fn f ->
        assert f.errors == []
        assert f.source.validations == [url: {:length, min: 3}]
        text_input f, :url
      end)

    assert contents ==
      ~s(<input id="bar_0_url" name="foo[0][url]" type="text" value="data1">) <>
      ~s(<input id="bar_1_url" name="foo[1][url]" type="text" value="data2">)
  end

  test "embeds many: inputs_for/4 with replaced changesets" do
    changeset =
      %User{permalinks: [%Permalink{id: 1, url: "data1"}, %Permalink{id: 2, url: "data2"}]}
      |> cast(%{"permalinks" => []}, ~w())
      |> cast_embed(:permalinks)

    input = ~r(<input id="user_permalinks_0_url".*<input id="user_permalinks_1_url")

    refute safe_inputs_for(changeset, :permalinks, [], fn f ->
      text_input f, :url
    end) =~ input
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
