defmodule Phoenix.Ecto.CheckRepoStatus do
  @moduledoc """
  A plug that does some checks on your application repos.

  Checks if the storage is up (database is created) or if there are any pending migrations.
  Both checks can raise an error if the conditions are not met.

  ## Plug options

    * `:otp_app` - name of the application which the repos are fetched from
    * `:get_migration_function` - function that returns the migrations for a given `repo`.
      Should return a list of tuples with three elements,
      e.g. `[{state :: :up | :down, version :: integer(), name :: String.t()]]`
      If `ecto_sql` dependency is loaded, uses `Ecto.Migrator.migrations/1` by default.
  """

  @behaviour Plug

  alias Plug.Conn

  def init(opts) do
    Keyword.fetch!(opts, :otp_app)
    opts
  end

  def call(%Conn{} = conn, opts) do
    repos = Application.get_env(opts[:otp_app], :ecto_repos, [])

    for repo <- repos, Process.whereis(repo) do
      check_storage_up!(repo)
      check_pending_migrations!(repo, opts)
    end

    conn
  end

  defp check_storage_up!(repo) do
    try do
      if Code.ensure_loaded?(repo.__adapter__) &&
           function_exported?(repo.__adapter__, :storage_status, 1) do
        repo.__adapter__.storage_status(repo.config())
      end
    rescue
      _ -> :ok
    else
      :down -> raise Phoenix.Ecto.StorageNotCreatedError, repo: repo
      _ -> :ok
    end
  end

  defp check_pending_migrations!(repo, opts) do
    try do
      # If the dependency `ecto_sql` is not loaded we can't check if
      # there are pending migrations so we try to fail gracefully here
      fallback_get_migrations =
        if Code.ensure_loaded?(Ecto.Migrator),
          do: &Ecto.Migrator.migrations/1,
          else: fn _repo -> [] end

      get_migrations = Keyword.get(opts, :get_migrations_function, fallback_get_migrations)

      repo
      |> get_migrations.()
      |> Enum.any?(fn {status, _version, _migration} -> status == :down end)
    rescue
      _ -> :ok
    else
      true -> raise Phoenix.Ecto.PendingMigrationError, repo: repo
      false -> :ok
    end
  end
end
