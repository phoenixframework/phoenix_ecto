defmodule Phoenix.Ecto.CheckRepoStatus do
  @moduledoc """
  A plug that does some checks on your application repos.

  Checks if the storage is up (database is created) or if there are any pending migrations.
  Both checks can raise an error if the conditions are not met.

  ## Plug options

    * `:otp_app` - name of the application which the repos are fetched from

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
    try do
      # If the dependency `ecto_sql` is not loaded we can't check if
      # there are pending migrations so we try to fail gracefully here
      fallback_get_migrations =
        if Code.ensure_loaded?(Ecto.Migrator),
          do: &Ecto.Migrator.migrations/1,
          else: fn _repo -> raise "to be rescued" end

      get_migrations = Keyword.get(opts, :get_migrations_function, fallback_get_migrations)

      repo
      |> get_migrations.()
      |> Enum.any?(fn {status, _version, _migration} -> status == :down end)
    rescue
      _ -> false
    else
      true -> raise Phoenix.Ecto.PendingMigrationError, repo: repo
      false -> true
    end
  end
end
