defmodule Phoenix.Ecto.CheckRepoStatus do
  @moduledoc """
  A plug that does some checks on your application repos.

  Checks if the storage is up (database is created) or if there are any pending migrations.
  Both checks can raise an error if the conditions are not met.

  ## Plug options

    * `:otp_app` - name of the application which the repos are fetched from
    * `:migration_paths` - a function that accepts a repo and returns a migration directory, or a list of migration directories, that is used to check for pending migrations
    * `:migration_lock` - the locking strategy used by the Ecto Adapter when checking for pending migrations. Set to `false` to disable migration locks.
  """

  @behaviour Plug

  alias Plug.Conn

  @migration_opts [:migration_lock]
  @compile {:no_warn_undefined, Ecto.Migrator}

  def init(opts) do
    Keyword.fetch!(opts, :otp_app)
    opts
  end

  def call(%Conn{} = conn, opts) do
    repos = Application.get_env(opts[:otp_app], :ecto_repos, [])

    for repo <- repos, Process.whereis(repo) do
      unless check_pending_migrations!(repo, opts) do
        check_storage_up!(repo)
      end
    end

    conn
  end

  defp check_storage_up!(repo) do
    try do
      adapter = repo.__adapter__()

      if Code.ensure_loaded?(adapter) && function_exported?(adapter, :storage_status, 1) do
        adapter.storage_status(repo.config())
      end
    rescue
      _ -> :ok
    else
      :down -> raise Phoenix.Ecto.StorageNotCreatedError, repo: repo
      _ -> :ok
    end
  end

  defp check_pending_migrations!(repo, opts) do
    repo_status =
      with {:ok, migration_directories} <- migration_directories(repo, opts),
           {:ok, migrations} <- migrations(repo, migration_directories, opts) do
        {:ok, migration_directories, migrations}
      end

    case repo_status do
      {:ok, migration_directories, migrations} ->
        has_pending =
          Enum.any?(migrations, fn {status, _version, _migration} -> status == :down end)

        if has_pending do
          raise Phoenix.Ecto.PendingMigrationError, repo: repo, directories: migration_directories
        else
          false
        end

      :error ->
        # could not determine migration directories and/or migrations because Ecto.Migrator is not available
        false
    end
  end

  defp migration_directories(repo, opts) do
    case Keyword.fetch(opts, :migration_paths) do
      {:ok, migration_directories_fn} ->
        migration_directories = migration_directories_fn.(repo)
        {:ok, List.wrap(migration_directories)}

      :error ->
        default_migration_directory(repo, opts)
    end
  end

  def migrations(repo, migration_directories, opts) do
    migration_opts = Keyword.take(opts, @migration_opts)

    case Keyword.fetch(opts, :mock_migrations_fn) do
      {:ok, migration_fn} ->
        migrations = get_migrations(migration_fn, repo, migration_directories, migration_opts)
        {:ok, migrations}

      :error ->
        if Code.ensure_loaded?(Ecto.Migrator) do
          {:ok, Ecto.Migrator.migrations(repo, migration_directories, migration_opts)}
        else
          :error
        end
    end
  end

  defp get_migrations(fun, repo, directories, _opts) when is_function(fun, 2) do
    fun.(repo, directories)
  end

  defp get_migrations(fun, repo, directories, opts) when is_function(fun, 3) do
    fun.(repo, directories, opts)
  end

  defp default_migration_directory(repo, opts) do
    case Keyword.fetch(opts, :mock_default_migration_directory_fn) do
      {:ok, migration_directories_fn} ->
        migration_directories = migration_directories_fn.(repo)
        {:ok, List.wrap(migration_directories)}

      :error ->
        if Code.ensure_loaded?(Ecto.Migrator) do
          {:ok, [Ecto.Migrator.migrations_path(repo)]}
        else
          :error
        end
    end
  end
end
