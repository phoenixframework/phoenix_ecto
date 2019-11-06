defmodule Phoenix.Ecto.StorageNotCreatedError do
  defexception [:repo]

  def message(%__MODULE__{repo: repo}),
    do: "The storage is not created for repo: `#{inspect(repo)}`. Try `mix ecto.create`"
end

defmodule Phoenix.Ecto.PendingMigrationError do
  defexception [:repo]

  def message(%__MODULE__{repo: repo}),
    do: "There are pending migrations for repo: `#{inspect(repo)}`. Try `mix ecto.migrate`"
end
