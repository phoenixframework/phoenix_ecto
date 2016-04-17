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

  defp add_metadata(conn, metadata) do
    encoded = {:v1, metadata} |> :erlang.term_to_binary |> Base.url_encode64
    put_req_header(conn, "user-agent", "PhoenixEcto/BeamMetadata (#{encoded})")
  end

  test "allows sandbox access to single repository" do
    metadata = Sandbox.metadata_for(MyRepo, self())
    assert metadata == %{repo: MyRepo, owner: self()}

    _conn = conn(:get, "/") |> add_metadata(metadata) |> call_plug

    assert_receive {:allowed, MyRepo}
  end

  test "allows sandbox access to multiple repositories" do
    repos = [MyRepoOne, MyRepoTwo]
    metadata = Sandbox.metadata_for(repos, self())
    assert metadata == %{repo: repos, owner: self()}

    _conn = conn(:get, "/") |> add_metadata(metadata) |> call_plug

    assert_receive {:allowed, MyRepoOne}
    assert_receive {:allowed, MyRepoTwo}
  end

  test "does not allow sandbox access without metadata" do
    conn(:get, "/") |> call_plug

    refute_receive {:allowed, _}
  end
end
