defmodule Phoenix.Ecto.SQL.Sandbox do
  @moduledoc """
  A plug to allow concurrent, transactional acceptance tests with Ecto.Adapters.SQL.Sandbox.

  ## Example

  This plug should only be used during tests. First, set a flag to
  enable it in `config/test.exs`:

      config :your_app, sql_sandbox: true

  And use the flag to conditionally add the plug to `lib/your_app/endpoint.ex`:

      if Application.get_env(:your_app, :sql_sandbox) do
        plug Phoenix.Ecto.SQL.Sandbox
      end

  Then, within an acceptance test, checkout a sandboxed connection as before.
  Before starting the test, access the endpoint at `path_for/2`. This sets a cookie
  that will be used on subsequent requests to allow access to the test's connection.
  Here's an example using [Hound](https://hex.pm/packages/hound):

      use Hound.Helpers

      setup do
        :ok = Ecto.Adapters.SQL.Sandbox.checkout(YourApp.Repo)
        Hound.start_session
        navigate_to Phoenix.Ecto.SQL.Sandbox.path_for(YourApp.Repo, self())
      end
  """

  import Plug.Conn

  @config_path "/phoenix/ecto/sql/sandbox/"
  @cookie_name "phoenix.ecto.sql.sandbox"

  def init(opts \\ []) do
    Keyword.get(opts, :sandbox, Ecto.Adapters.SQL.Sandbox)
  end

  def call(%{request_path: @config_path <> configuration} = conn, _sandbox) do
    conn |> put_resp_cookie(@cookie_name, configuration) |> send_resp(200, "OK") |> halt
  end

  def call(conn, sandbox) do
    conn |> fetch_cookies |> allow_sandbox_access(sandbox)
  end

  @doc """
  Returns the path to set the connection ownership cookie.

  Sending this cookie in subsequent requests will allow
  the endpoint to access the database connection checked
  out by the test process.
  """
  @spec path_for(Ecto.Repo.t | [Ecto.Repo.t], pid) :: String.t
  def path_for(repo_or_repos, pid) when is_pid(pid) do
    repos = repo_or_repos |> List.wrap |> Enum.map_join("|", &Atom.to_string/1)
    "#{@config_path}#{:erlang.pid_to_list(pid)}|#{repos}"
  end

  defp allow_sandbox_access(%{req_cookies: %{@cookie_name => configuration}} = conn, sandbox) do
    [pid_string|repo_strings] = configuration |> URI.decode |> String.split("|")

    owner = to_pid(pid_string)
    repos = Enum.map(repo_strings, &String.to_atom/1)

    Enum.each(repos, &sandbox.allow(&1, owner, self()))

    conn
  end
  defp allow_sandbox_access(conn, _sandbox), do: conn

  defp to_pid(string) do
    string |> String.to_char_list |> :erlang.list_to_pid
  end
end
