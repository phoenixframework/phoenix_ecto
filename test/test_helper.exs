defmodule Permalink do
  use Ecto.Schema

  embedded_schema do
    field :url
  end

  def changeset(permalink, params) do
    import Ecto.Changeset

    permalink
    |> cast(params, ~w(url)a)
    |> validate_required(:url)
    |> validate_length(:url, min: 3)
  end
end

defmodule Comment do
  use Ecto.Schema

  schema "comments" do
    field :body
    field :position, :integer
    has_many :child_comments, Comment
  end

  def changeset(comment, params) do
    import Ecto.Changeset

    comment
    |> cast(params, ~w(body)a)
    |> validate_required(:body)
    |> validate_length(:body, min: 3)
    |> cast_assoc(:child_comments)
  end

  def custom_changeset(comment, params, required_length) do
    import Ecto.Changeset

    comment
    |> cast(params, ~w(body)a)
    |> validate_length(:body, min: required_length)
  end

  def changeset_with_position(comment, params, index) do
    changeset(comment, params)
    |> Ecto.Changeset.put_change(:position, index)
  end
end

defmodule User do
  use Ecto.Schema

  schema "users" do
    field :name
    field :title
    field :age, :integer
    field :score, :decimal
    embeds_one :permalink, Permalink, on_replace: :delete
    embeds_many :permalinks, Permalink, on_replace: :delete
    has_one :comment, Comment, on_replace: :delete
    has_many :comments, Comment, on_replace: :delete
  end
end

defmodule SchemalessUser do
  defstruct name: nil
end

ExUnit.start()
