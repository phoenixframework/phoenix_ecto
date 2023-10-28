defmodule PhoenixEcto.InputsForTest do
  use ExUnit.Case, async: true

  import Ecto.Changeset

  defp to_inputs_form(changeset, field, opts \\ []) do
    form = Phoenix.HTML.FormData.to_form(changeset, [])
    Phoenix.HTML.FormData.to_form(changeset, form, field, opts)
  end

  ## has_one

  test "has one: simple" do
    changeset =
      %User{}
      |> cast(%{}, ~w()a)
      |> cast_assoc(:comment)

    [f] = to_inputs_form(changeset, :comment)
    assert f.impl == Phoenix.HTML.FormData.Ecto.Changeset
    assert f.errors == []
    assert f.source.validations == [body: {:length, min: 3}]

    assert %Phoenix.HTML.FormField{
             id: "user_comment_body",
             name: "user[comment][body]",
             value: nil
           } = f[:body]
  end

  test "has one: with data" do
    changeset =
      %User{comment: %Comment{body: "data"}}
      |> cast(%{}, ~w()a)
      |> cast_assoc(:comment)

    [f] = to_inputs_form(changeset, :comment)
    assert f.errors == []
    assert f.source.validations == [body: {:length, min: 3}]

    assert %Phoenix.HTML.FormField{
             id: "user_comment_body",
             name: "user[comment][body]",
             value: "data"
           } = f[:body]
  end

  test "has one: with params" do
    changeset =
      %User{comment: %Comment{body: "data"}}
      |> cast(%{"comment" => %{"body" => "ht"}}, ~w()a)
      |> cast_assoc(:comment)

    [f] = to_inputs_form(changeset, :comment)
    assert f.errors == []
    assert f.source.validations == [body: {:length, min: 3}]

    assert %Phoenix.HTML.FormField{
             id: "user_comment_body",
             name: "user[comment][body]",
             value: "ht"
           } = f[:body]

    [f] = to_inputs_form(%{changeset | action: :insert}, :comment)

    assert f.errors == [
             body:
               {"should be at least %{count} character(s)",
                count: 3, validation: :length, kind: :min, type: :string}
           ]

    assert f.source.validations == [body: {:length, min: 3}]

    assert %Phoenix.HTML.FormField{
             id: "user_comment_body",
             name: "user[comment][body]",
             value: "ht"
           } = f[:body]
  end

  test "has one: with custom id and name" do
    changeset =
      %User{comment: %Comment{body: "data"}}
      |> cast(%{"comment" => %{"body" => "given"}}, ~w()a)
      |> cast_assoc(:comment)

    [f] = to_inputs_form(changeset, :comment, as: "foo", id: "bar")

    assert %Phoenix.HTML.FormField{
             id: "bar_body",
             name: "foo[body]",
             value: "given"
           } = f[:body]
  end

  test "has one: with replaced changesets" do
    changeset =
      %User{comment: %Comment{id: 1}}
      |> cast(%{"comment" => nil}, ~w()a)
      |> cast_assoc(:comment)

    [] = to_inputs_form(changeset, :comment, as: "foo", id: "bar")
  end

  ## has_many

  test "has many: empty" do
    changeset =
      %User{}
      |> cast(%{}, ~w()a)
      |> cast_assoc(:comments)

    [] = to_inputs_form(changeset, :comments)
  end

  test "has many: with data" do
    changeset =
      %User{comments: [%Comment{body: "data1"}, %Comment{body: "data2"}]}
      |> cast(%{}, ~w()a)
      |> cast_assoc(:comments)

    [f1, f2] = to_inputs_form(changeset, :comments)
    assert f1.impl == Phoenix.HTML.FormData.Ecto.Changeset
    assert f1.index == 0
    assert f1.errors == []
    assert f1.source.validations == [body: {:length, min: 3}]

    assert %Phoenix.HTML.FormField{
             id: "user_comments_0_body",
             name: "user[comments][0][body]",
             value: "data1"
           } = f1[:body]

    assert f2.impl == Phoenix.HTML.FormData.Ecto.Changeset
    assert f2.index == 1
    assert f2.errors == []
    assert f2.source.validations == [body: {:length, min: 3}]

    assert %Phoenix.HTML.FormField{
             id: "user_comments_1_body",
             name: "user[comments][1][body]",
             value: "data2"
           } = f2[:body]
  end

  test "has many: with prepend and append" do
    changeset =
      %User{comments: [%Comment{body: "def1"}, %Comment{body: "def2"}]}
      |> cast(%{}, ~w()a)
      |> cast_assoc(:comments)
      |> Map.put(:action, :insert)

    [f0, f1, f2, f3] =
      to_inputs_form(changeset, :comments,
        prepend: [%Comment{body: "prepend"}],
        append: [%Comment{body: "append"}]
      )

    assert %Phoenix.HTML.FormField{
             id: "user_comments_0_body",
             name: "user[comments][0][body]",
             value: "prepend"
           } = f0[:body]

    assert %Phoenix.HTML.FormField{
             id: "user_comments_1_body",
             name: "user[comments][1][body]",
             value: "def1"
           } = f1[:body]

    assert %Phoenix.HTML.FormField{
             id: "user_comments_2_body",
             name: "user[comments][2][body]",
             value: "def2"
           } = f2[:body]

    assert %Phoenix.HTML.FormField{
             id: "user_comments_3_body",
             name: "user[comments][3][body]",
             value: "append"
           } = f3[:body]
  end

  test "has many: with prepend and append with data" do
    changeset =
      %User{comments: [%Comment{id: "a", body: "def1"}, %Comment{id: "b", body: "def2"}]}
      |> cast(%{}, ~w()a)
      |> cast_assoc(:comments)
      |> Map.put(:action, :insert)

    [f0, f1, f2, f3] =
      to_inputs_form(changeset, :comments,
        prepend: [%Comment{body: "prepend"}],
        append: [%Comment{body: "append"}]
      )

    assert f0.hidden == []

    assert %Phoenix.HTML.FormField{
             id: "user_comments_0_body",
             name: "user[comments][0][body]",
             value: "prepend"
           } = f0[:body]

    assert f1.hidden == [id: "a"]

    assert %Phoenix.HTML.FormField{
             id: "user_comments_1_body",
             name: "user[comments][1][body]",
             value: "def1"
           } = f1[:body]

    assert f2.hidden == [id: "b"]

    assert %Phoenix.HTML.FormField{
             id: "user_comments_2_body",
             name: "user[comments][2][body]",
             value: "def2"
           } = f2[:body]

    assert f3.hidden == []

    assert %Phoenix.HTML.FormField{
             id: "user_comments_3_body",
             name: "user[comments][3][body]",
             value: "append"
           } = f3[:body]
  end

  test "has many: with prepend and append with params" do
    comments = [%Comment{id: 1, body: "data1"}, %Comment{id: 2, body: "data2"}]

    changeset =
      %User{comments: comments}
      |> cast(
        %{"comments" => [%{"id" => "1", "body" => "p1"}, %{"id" => "2", "body" => "p2"}]},
        ~w()a
      )
      |> cast_assoc(:comments)
      |> Map.put(:action, :insert)

    [f1, f2] =
      to_inputs_form(changeset, :comments,
        prepend: [%Comment{body: "prepend"}],
        append: [%Comment{body: "append"}]
      )

    assert f1.hidden == [id: 1]

    assert %Phoenix.HTML.FormField{
             id: "user_comments_0_body",
             name: "user[comments][0][body]",
             value: "p1"
           } = f1[:body]

    assert f2.hidden == [id: 2]

    assert %Phoenix.HTML.FormField{
             id: "user_comments_1_body",
             name: "user[comments][1][body]",
             value: "p2"
           } = f2[:body]
  end

  test "has many: with custom id and name" do
    changeset =
      %User{comments: [%Comment{body: "data1"}, %Comment{body: "data2"}]}
      |> cast(%{}, ~w()a)
      |> cast_assoc(:comments)

    [f0, f1] = to_inputs_form(changeset, :comments, as: "foo", id: "bar")

    assert %Phoenix.HTML.FormField{
             id: "bar_0_body",
             name: "foo[0][body]",
             value: "data1"
           } = f0[:body]

    assert %Phoenix.HTML.FormField{
             id: "bar_1_body",
             name: "foo[1][body]",
             value: "data2"
           } = f1[:body]
  end

  test "has many: with replaced changesets" do
    changeset =
      %User{comments: [%Comment{id: 1, body: "data1"}, %Comment{id: 2, body: "data2"}]}
      |> cast(%{"comments" => []}, ~w()a)
      |> cast_assoc(:comments)

    [] = to_inputs_form(changeset, :comments)
  end

  test "has many: with custom changeset MFA" do
    required_length = 5

    changeset =
      %User{comments: [%Comment{body: "data1"}, %Comment{body: "data2"}]}
      |> cast(%{}, ~w()a)
      |> cast_assoc(:comments, with: {Comment, :custom_changeset, [required_length]})

    [f1, f2] = to_inputs_form(changeset, :comments)

    assert %Phoenix.HTML.FormField{
             id: "user_comments_0_body",
             name: "user[comments][0][body]",
             value: "data1"
           } = f1[:body]

    assert %Phoenix.HTML.FormField{
             id: "user_comments_1_body",
             name: "user[comments][1][body]",
             value: "data2"
           } = f2[:body]
  end

  test "has many: with custom changeset function" do
    changeset =
      %User{comments: [%Comment{body: "data1"}, %Comment{body: "data2"}]}
      |> cast(%{}, ~w()a)
      |> cast_assoc(:comments, with: &Comment.changeset_with_position/3)

    [f1, f2] = to_inputs_form(changeset, :comments)

    assert %Phoenix.HTML.FormField{
             id: "user_comments_0_position",
             name: "user[comments][0][position]",
             value: 0
           } = f1[:position]

    assert %Phoenix.HTML.FormField{
             id: "user_comments_1_position",
             name: "user[comments][1][position]",
             value: 1
           } = f2[:position]
  end

  ## embed_one

  test "embed one: simple" do
    changeset =
      %User{}
      |> cast(%{}, ~w()a)
      |> cast_embed(:permalink)

    [f] = to_inputs_form(changeset, :permalink)
    assert f.impl == Phoenix.HTML.FormData.Ecto.Changeset
    assert f.errors == []
    assert f.source.validations == [url: {:length, min: 3}]

    assert %Phoenix.HTML.FormField{
             id: "user_permalink_url",
             name: "user[permalink][url]",
             value: nil
           } = f[:url]
  end

  test "embed one: with data" do
    changeset =
      %User{permalink: %Permalink{url: "data"}}
      |> cast(%{}, ~w()a)
      |> cast_embed(:permalink)

    [f] = to_inputs_form(changeset, :permalink)
    assert f.errors == []
    assert f.source.validations == [url: {:length, min: 3}]

    assert %Phoenix.HTML.FormField{
             id: "user_permalink_url",
             name: "user[permalink][url]",
             value: "data"
           } = f[:url]
  end

  test "embed one: with params" do
    changeset =
      %User{permalink: %Permalink{url: "data"}}
      |> cast(%{"permalink" => %{"url" => "ht"}}, ~w()a)
      |> cast_embed(:permalink)

    [f] = to_inputs_form(changeset, :permalink)
    assert f.errors == []
    assert f.source.validations == [url: {:length, min: 3}]

    assert %Phoenix.HTML.FormField{
             id: "user_permalink_url",
             name: "user[permalink][url]",
             value: "ht"
           } = f[:url]

    [f] = to_inputs_form(%{changeset | action: :insert}, :permalink)

    assert f.errors == [
             url:
               {"should be at least %{count} character(s)",
                count: 3, validation: :length, kind: :min, type: :string}
           ]

    assert f.source.validations == [url: {:length, min: 3}]

    assert %Phoenix.HTML.FormField{
             id: "user_permalink_url",
             name: "user[permalink][url]",
             value: "ht"
           } = f[:url]
  end

  test "embed one: with custom id and name" do
    changeset =
      %User{permalink: %Permalink{url: "data"}}
      |> cast(%{"permalink" => %{"url" => "given"}}, ~w()a)
      |> cast_embed(:permalink)

    [f] = to_inputs_form(changeset, :permalink, as: "foo", id: "bar")

    assert %Phoenix.HTML.FormField{
             id: "bar_url",
             name: "foo[url]",
             value: "given"
           } = f[:url]
  end

  test "embed one: with replaced changesets" do
    changeset =
      %User{permalink: %Permalink{id: 1}}
      |> cast(%{"permalink" => nil}, ~w()a)
      |> cast_embed(:permalink)

    [] = to_inputs_form(changeset, :permalink, as: "foo", id: "bar")
  end

  ## embed_many

  test "embed many: empty" do
    changeset =
      %User{}
      |> cast(%{}, ~w()a)
      |> cast_embed(:permalinks)

    [] = to_inputs_form(changeset, :permalinks)
  end

  test "embed many: with data" do
    changeset =
      %User{permalinks: [%Permalink{url: "data1"}, %Permalink{url: "data2"}]}
      |> cast(%{}, ~w()a)
      |> cast_embed(:permalinks)

    [f1, f2] = to_inputs_form(changeset, :permalinks)
    assert f1.impl == Phoenix.HTML.FormData.Ecto.Changeset
    assert f1.index == 0
    assert f1.errors == []
    assert f1.source.validations == [url: {:length, min: 3}]

    assert %Phoenix.HTML.FormField{
             id: "user_permalinks_0_url",
             name: "user[permalinks][0][url]",
             value: "data1"
           } = f1[:url]

    assert f2.impl == Phoenix.HTML.FormData.Ecto.Changeset
    assert f2.index == 1
    assert f2.errors == []
    assert f2.source.validations == [url: {:length, min: 3}]

    assert %Phoenix.HTML.FormField{
             id: "user_permalinks_1_url",
             name: "user[permalinks][1][url]",
             value: "data2"
           } = f2[:url]
  end

  test "embed many: with prepend and append" do
    changeset =
      %User{permalinks: [%Permalink{url: "def1"}, %Permalink{url: "def2"}]}
      |> cast(%{}, ~w()a)
      |> cast_embed(:permalinks)
      |> Map.put(:action, :insert)

    [f0, f1, f2, f3] =
      to_inputs_form(changeset, :permalinks,
        prepend: [%Permalink{url: "prepend"}],
        append: [%Permalink{url: "append"}]
      )

    assert %Phoenix.HTML.FormField{
             id: "user_permalinks_0_url",
             name: "user[permalinks][0][url]",
             value: "prepend"
           } = f0[:url]

    assert %Phoenix.HTML.FormField{
             id: "user_permalinks_1_url",
             name: "user[permalinks][1][url]",
             value: "def1"
           } = f1[:url]

    assert %Phoenix.HTML.FormField{
             id: "user_permalinks_2_url",
             name: "user[permalinks][2][url]",
             value: "def2"
           } = f2[:url]

    assert %Phoenix.HTML.FormField{
             id: "user_permalinks_3_url",
             name: "user[permalinks][3][url]",
             value: "append"
           } = f3[:url]
  end

  test "embed many: with prepend and append with data" do
    changeset =
      %User{permalinks: [%Permalink{id: "a", url: "def1"}, %Permalink{id: "b", url: "def2"}]}
      |> cast(%{}, ~w()a)
      |> cast_embed(:permalinks)
      |> Map.put(:action, :insert)

    [f0, f1, f2, f3] =
      to_inputs_form(changeset, :permalinks,
        prepend: [%Permalink{url: "prepend"}],
        append: [%Permalink{url: "append"}]
      )

    assert f0.hidden == []

    assert %Phoenix.HTML.FormField{
             id: "user_permalinks_0_url",
             name: "user[permalinks][0][url]",
             value: "prepend"
           } = f0[:url]

    assert f1.hidden == [id: "a"]

    assert %Phoenix.HTML.FormField{
             id: "user_permalinks_1_url",
             name: "user[permalinks][1][url]",
             value: "def1"
           } = f1[:url]

    assert f2.hidden == [id: "b"]

    assert %Phoenix.HTML.FormField{
             id: "user_permalinks_2_url",
             name: "user[permalinks][2][url]",
             value: "def2"
           } = f2[:url]

    assert f3.hidden == []

    assert %Phoenix.HTML.FormField{
             id: "user_permalinks_3_url",
             name: "user[permalinks][3][url]",
             value: "append"
           } = f3[:url]
  end

  test "embed many: with prepend and append with params" do
    permalinks = [%Permalink{id: 1, url: "data1"}, %Permalink{id: 2, url: "data2"}]

    changeset =
      %User{permalinks: permalinks}
      |> cast(
        %{"permalinks" => [%{"id" => "1", "url" => "p1"}, %{"id" => "2", "url" => "p2"}]},
        ~w()a
      )
      |> cast_embed(:permalinks)
      |> Map.put(:action, :insert)

    [f1, f2] =
      to_inputs_form(changeset, :permalinks,
        prepend: [%Permalink{url: "prepend"}],
        append: [%Permalink{url: "append"}]
      )

    assert f1.hidden == []

    assert %Phoenix.HTML.FormField{
             id: "user_permalinks_0_url",
             name: "user[permalinks][0][url]",
             value: "p1"
           } = f1[:url]

    assert f2.hidden == []

    assert %Phoenix.HTML.FormField{
             id: "user_permalinks_1_url",
             name: "user[permalinks][1][url]",
             value: "p2"
           } = f2[:url]
  end

  test "embed many: with custom id and name" do
    changeset =
      %User{permalinks: [%Permalink{url: "data1"}, %Permalink{url: "data2"}]}
      |> cast(%{}, ~w()a)
      |> cast_embed(:permalinks)

    [f0, f1] = to_inputs_form(changeset, :permalinks, as: "foo", id: "bar")

    assert %Phoenix.HTML.FormField{
             id: "bar_0_url",
             name: "foo[0][url]",
             value: "data1"
           } = f0[:url]

    assert %Phoenix.HTML.FormField{
             id: "bar_1_url",
             name: "foo[1][url]",
             value: "data2"
           } = f1[:url]
  end

  test "embed many: with replaced changesets" do
    changeset =
      %User{permalinks: [%Permalink{id: 1, url: "data1"}, %Permalink{id: 2, url: "data2"}]}
      |> cast(%{"permalinks" => []}, ~w()a)
      |> cast_embed(:permalinks)

    [] = to_inputs_form(changeset, :permalinks)
  end
end
