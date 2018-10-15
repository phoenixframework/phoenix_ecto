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
  end

  def changeset(comment, params) do
    import Ecto.Changeset
    comment
    |> cast(params, ~w(body)a)
    |> validate_required(:body)
    |> validate_length(:body, min: 3)
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
