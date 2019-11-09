defmodule Phoenix.Ecto.SQL.SandboxSession do
  @moduledoc false
  use GenServer, restart: :temporary

  @timeout 15_000

  def start_link({repo, client, opts}) do
    GenServer.start_link(__MODULE__, [repo, client, opts])
  end

  def init([repo, client, opts]) do
    timeout = opts[:timeout] || @timeout
    sandbox = opts[:sandbox] || Ecto.Adapters.SQL.Sandbox

    :ok = checkout_connection(sandbox, repo, client)
    Process.send_after(self(), :timeout, timeout)

    {:ok, %{repo: repo, client: client, sandbox: sandbox}}
  end

  def handle_call(:checkin, _from, state) do
    :ok = checkin_connection(state.sandbox, state.repo, state.client)
    {:stop, :shutdown, :ok, state}
  end

  def handle_info(:timeout, state) do
    :ok = checkin_connection(state.sandbox, state.repo, state.client)
    {:stop, :shutdown, state}
  end

  def handle_info({:allowed, repo}, state) do
    send(state.client, {:allowed, repo})
    {:noreply, state}
  end

  defp checkin_connection(sandbox, repo, client) do
    sandbox.checkin(repo, client: client)
  end

  defp checkout_connection(sandbox, repo, client) do
    sandbox.checkout(repo, client: client)
  end
end
