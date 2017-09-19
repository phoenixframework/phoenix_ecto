defmodule PhoenixEcto.SQL.SandboxTest do
  use ExUnit.Case, async: true
  use Plug.Test

  alias Phoenix.Ecto.SQL.Sandbox

  defmodule MockSandbox do
    def checkout(repo, opts) do
      send opts[:client], {:checkout, repo}
      :ok
    end

    def checkin(repo, opts) do
      send opts[:client], {:checkin, repo}
      :ok
    end

    def allow(repo, owner, _allowed) do
      send owner, {:allowed, repo}
    end
  end

  defp call_plug_with_checkout(conn, opts \\ []) do
    opts = Enum.into(opts, at: "/sandbox", repo: MyRepo)
    call_plug(conn, opts)
  end

  defp call_plug(conn, opts \\ []) do
    opts =
      opts
      |> Enum.into(sandbox: MockSandbox)
      |> Sandbox.init()

    Sandbox.call(conn, opts)
  end

  defp add_metadata(conn, metadata, header_key) do
    encoded = {:v1, metadata} |> :erlang.term_to_binary |> Base.url_encode64()
    put_req_header(conn, header_key, "PhoenixEcto/BeamMetadata (#{encoded})")
  end

  test "allows sandbox access to single repository" do
    metadata = Sandbox.metadata_for(MyRepo, self())
    assert metadata == %{repo: MyRepo, owner: self()}

    _conn =
      conn(:get, "/")
      |> add_metadata(metadata, "user-agent")
      |> call_plug()

    assert_receive {:allowed, MyRepo}
  end

  test "allows sandbox access to multiple repositories" do
    repos = [MyRepoOne, MyRepoTwo]
    metadata = Sandbox.metadata_for(repos, self())
    assert metadata == %{repo: repos, owner: self()}

    _conn =
      conn(:get, "/")
      |> add_metadata(metadata, "user-agent")
      |> call_plug()

    assert_receive {:allowed, MyRepoOne}
    assert_receive {:allowed, MyRepoTwo}
  end

  test "allows customized header" do
    metadata = Sandbox.metadata_for(MyRepo, self())
    assert metadata == %{repo: MyRepo, owner: self()}

    _conn =
      conn(:get, "/")
      |> add_metadata(metadata, "x-custom")
      |> call_plug(header: "x-custom")

    assert_receive {:allowed, MyRepo}
  end


  test "does not allow sandbox access without metadata" do
    conn(:get, "/") |> call_plug()

    refute_receive {:allowed, _}
  end

  test "encodes and decodes metadata" do
    metadata = Sandbox.metadata_for(MyRepo, self())
    encoded_meta = Sandbox.encode_metadata(metadata)

    assert "BeamMetadata " <> _ = encoded_meta
    assert metadata == Sandbox.decode_metadata(encoded_meta)
  end

  test "checks out/in connection through sandbox owner at path" do
    # start new sandbox owner
    conn = call_plug_with_checkout(conn(:post, "/sandbox"))
    assert "BeamMetadata" <> _ = user_agent = conn.resp_body
    assert conn.halted
    assert conn.status == 200
    assert_receive {:checkout, MyRepo}

    # no allow with missing header
    conn = call_plug_with_checkout(conn(:get, "/"))
    refute conn.halted
    refute_receive {:allowed, MyRepo}

    # allows new request with metadata in header
    conn =
      conn(:get, "/")
      |> put_req_header("user-agent", user_agent)
      |> call_plug_with_checkout()

    refute conn.halted
    assert_receive {:allowed, MyRepo}

    # checks in request with metadata
    conn =
      conn(:delete, "/sandbox")
      |> put_req_header("user-agent", user_agent)
      |> call_plug_with_checkout()

    assert conn.status == 200
    assert conn.halted

    # old user agent refuses owner who has been checked in
    _conn =
      conn(:get, "/")
      |> put_req_header("user-agent", user_agent)
      |> call_plug_with_checkout()

    refute_receive {:allowed, MyRepo}
  end
end
