defmodule PhoenixEcto.SQL.SandboxTest do
  use ExUnit.Case, async: true
  use Plug.Test

  alias Phoenix.Ecto.SQL.Sandbox

  defmodule MockSandbox do
    def allow(repo, owner, _allowed) do
      send owner, {:allowed, repo}
    end
  end

  defp call_plug(conn) do
    opts = Sandbox.init(sandbox: MockSandbox)
    Sandbox.call(conn, opts)
  end

  test "allows sandbox access to subsequent connections with proper cookie" do
    old_conn = conn(:get, Sandbox.path_for(MyRepo, self())) |> call_plug
    _conn = recycle_cookies(conn(:get, "/"), old_conn) |> call_plug

    assert_receive {:allowed, MyRepo}
  end

  test "allows sandbox access to multiple repositories" do
    old_conn = conn(:get, Sandbox.path_for([MyRepoOne, MyRepoTwo], self())) |> call_plug
    _conn = recycle_cookies(conn(:get, "/"), old_conn) |> call_plug

    assert_receive {:allowed, MyRepoOne}
    assert_receive {:allowed, MyRepoTwo}
  end

  test "does not allow sandbox access without cookie" do
    conn(:get, "/") |> call_plug

    refute_receive {:allowed, _}
  end
end
