defmodule Phoenix.Ecto.CheckRepoStatusTest do
  use ExUnit.Case, async: true
  use Plug.Test

  alias Phoenix.Ecto.CheckRepoStatus

  defmodule LongLivedProcess do
    def run do
      Process.sleep(1_000)
      run()
    end
  end

  defmodule StorageUpRepo do
    defmodule Adapter, do: def(storage_status(_repo_config), do: :up)
    def config, do: []
    def __adapter__, do: Adapter
  end

  defmodule StorageDownRepo do
    defmodule Adapter, do: def(storage_status(_repo_config), do: :down)
    def config, do: []
    def __adapter__, do: Adapter
  end

  defmodule NoStorageStatusRepo do
    defmodule Adapter, do: nil
    def config, do: []
    def __adapter__, do: Adapter
  end

  defmodule StorageErrorRepo do
    defmodule Adapter,
      do: def(storage_status(_repo_config), do: {:error, %{message: "Adapter error"}})

    def config, do: []
    def __adapter__, do: Adapter
  end

  test "does not raise an error when the storage is created and there are no pending migrations for a repo" do
    Process.register(self(), StorageUpRepo)
    Application.put_env(:check_repo_ready, :ecto_repos, [StorageUpRepo])
    mock_migrations_fn = fn _repo, _directories, _opts -> [] end

    conn = conn(:get, "/")

    assert conn ==
             CheckRepoStatus.call(
               conn,
               otp_app: :check_repo_ready,
               mock_migrations_fn: mock_migrations_fn
             )
  after
    Application.delete_env(:check_repo_ready, :ecto_repos)
    Process.unregister(StorageUpRepo)
  end

  test "raises an error when there is no storage created for a repo" do
    Process.register(self(), StorageDownRepo)
    Application.put_env(:check_repo_ready, :ecto_repos, [StorageDownRepo])
    mock_migrations_fn = fn _repo, _directories, _opts -> raise "no migrations" end

    conn = conn(:get, "/")

    assert_raise(Phoenix.Ecto.StorageNotCreatedError, fn ->
      CheckRepoStatus.call(
        conn,
        otp_app: :check_repo_ready,
        mock_migrations_fn: mock_migrations_fn
      )
    end)
  after
    Application.delete_env(:check_repo_ready, :ecto_repos)
    Process.unregister(StorageDownRepo)
  end

  test "raises an error when there are pending migrations for any repo" do
    Process.register(self(), StorageUpRepo)
    Application.put_env(:check_repo_ready, :ecto_repos, [StorageUpRepo])
    mock_migrations_fn = fn _repo, _directories, _opts -> [{:down, 1, "migration"}] end

    conn = conn(:get, "/")

    exception =
      assert_raise(Phoenix.Ecto.PendingMigrationError, fn ->
        CheckRepoStatus.call(
          conn,
          otp_app: :check_repo_ready,
          mock_migrations_fn: mock_migrations_fn
        )
      end)

    assert exception.directories == []
  after
    Application.delete_env(:check_repo_ready, :ecto_repos)
    Process.unregister(StorageUpRepo)
  end

  test "supports the Ecto's migration_lock option" do
    Process.register(self(), StorageUpRepo)
    Application.put_env(:check_repo_ready, :ecto_repos, [StorageUpRepo])
    mock_migrations_fn = fn _repo, _directories, _opts -> [{:down, 1, "migration"}] end

    conn = conn(:get, "/")

    assert_raise(Phoenix.Ecto.PendingMigrationError, fn ->
      CheckRepoStatus.call(
        conn,
        otp_app: :check_repo_ready,
        mock_migrations_fn: mock_migrations_fn,
        migration_lock: false
      )
    end)
  after
    Application.delete_env(:check_repo_ready, :ecto_repos)
    Process.unregister(StorageUpRepo)
  end

  test "supports the 'migration_paths' option" do
    Process.register(self(), StorageUpRepo)
    Application.put_env(:check_repo_ready, :ecto_repos, [StorageUpRepo])

    conn = conn(:get, "/")

    # set to a single directory
    mock_migrations_fn = fn _repo, ["foo"], _opts -> [{:down, 1, "migration"}] end

    exception =
      assert_raise(Phoenix.Ecto.PendingMigrationError, fn ->
        CheckRepoStatus.call(
          conn,
          otp_app: :check_repo_ready,
          migration_paths: fn _repo -> "foo" end,
          mock_migrations_fn: mock_migrations_fn
        )
      end)

    assert exception.directories == ["foo"]

    # set to multiple directories
    mock_migrations_fn = fn _repo, ["foo", "bar"], _opts -> [{:down, 1, "migration"}] end

    exception =
      assert_raise(Phoenix.Ecto.PendingMigrationError, fn ->
        CheckRepoStatus.call(
          conn,
          otp_app: :check_repo_ready,
          migration_paths: fn _repo -> ["foo", "bar"] end,
          mock_migrations_fn: mock_migrations_fn
        )
      end)

    assert exception.directories == ["foo", "bar"]
  after
    Application.delete_env(:check_repo_ready, :ecto_repos)
    Process.unregister(StorageUpRepo)
  end

  test "does not raise an error when the repo's adapter does not implement storage_status/1" do
    Process.register(self(), StorageStatusRepo)
    Application.put_env(:check_repo_ready, :ecto_repos, [NoStorageStatusRepo])
    mock_migrations_fn = fn _repo, _directories, _opts -> raise "failed" end

    conn = conn(:get, "/")

    assert conn ==
             CheckRepoStatus.call(conn,
               otp_app: :check_repo_ready,
               mock_migrations_fn: mock_migrations_fn
             )
  after
    Application.delete_env(:check_repo_ready, :ecto_repos)
    Process.unregister(StorageStatusRepo)
  end

  test "does not raise an error when using the fallback get_migration_function" do
    Process.register(self(), StorageUpRepo)
    Application.put_env(:check_repo_ready, :ecto_repos, [StorageUpRepo])

    conn = conn(:get, "/")

    assert conn == CheckRepoStatus.call(conn, otp_app: :check_repo_ready)
  after
    Application.delete_env(:check_repo_ready, :ecto_repos)
    Process.unregister(StorageUpRepo)
  end

  test "does not raise an error when storage_status returns {:error, term()}" do
    Process.register(self(), StorageErrorRepo)
    Application.put_env(:check_repo_ready, :ecto_repos, [StorageErrorRepo])
    mock_migrations_fn = fn _repo, _directories, _opts -> [] end

    conn = conn(:get, "/")

    assert conn ==
             CheckRepoStatus.call(conn,
               otp_app: :check_repo_ready,
               mock_migrations_fn: mock_migrations_fn
             )
  after
    Application.delete_env(:check_repo_ready, :ecto_repos)
    Process.unregister(StorageErrorRepo)
  end

  test "does not raise an error when the storage is created and there are no pending migrations for multiple repos" do
    Process.register(self(), StorageUpRepo)
    Application.put_env(:check_repo_ready, :ecto_repos, [StorageUpRepo, StorageUpRepo])
    mock_migrations_fn = fn _repo, _directories, _opts -> [] end

    conn = conn(:get, "/")

    assert conn ==
             CheckRepoStatus.call(
               conn,
               otp_app: :check_repo_ready,
               mock_migrations_fn: mock_migrations_fn
             )
  after
    Application.delete_env(:check_repo_ready, :ecto_repos)
    Process.unregister(StorageUpRepo)
  end

  test "raises an error when one of multiple repos does not have the database created" do
    Process.register(self(), StorageUpRepo)
    Process.register(spawn_link(&LongLivedProcess.run/0), StorageDownRepo)
    Application.put_env(:check_repo_ready, :ecto_repos, [StorageUpRepo, StorageDownRepo])
    mock_migrations_fn = fn _repo, _directories, _opts -> raise "no migrations" end

    conn = conn(:get, "/")

    assert_raise(Phoenix.Ecto.StorageNotCreatedError, fn ->
      CheckRepoStatus.call(
        conn,
        otp_app: :check_repo_ready,
        mock_migrations_fn: mock_migrations_fn
      )
    end)
  after
    Application.delete_env(:check_repo_ready, :ecto_repos)
    Process.unregister(StorageUpRepo)
    Process.unregister(StorageDownRepo)
  end

  test "raises an error when one of multiple repos has pending migrations" do
    Process.register(self(), StorageUpRepo)
    Process.register(spawn_link(&LongLivedProcess.run/0), NoStorageStatusRepo)
    Application.put_env(:check_repo_ready, :ecto_repos, [StorageUpRepo, NoStorageStatusRepo])

    mock_migrations_fn = fn
      StorageUpRepo, _directories, _opts -> []
      NoStorageStatusRepo, _directories, _opts -> [{:down, 1, "migration"}]
    end

    conn = conn(:get, "/")

    exception =
      assert_raise(Phoenix.Ecto.PendingMigrationError, fn ->
        CheckRepoStatus.call(
          conn,
          otp_app: :check_repo_ready,
          mock_migrations_fn: mock_migrations_fn
        )
      end)

    assert exception.directories == []
  after
    Application.delete_env(:check_repo_ready, :ecto_repos)
    Process.unregister(StorageUpRepo)
    Process.unregister(NoStorageStatusRepo)
  end
end
