defmodule Phoenix.Ecto.SQL.SandboxSupervisor do
  @moduledoc false
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    supervise([
      worker(Phoenix.Ecto.SQL.SandboxSession, [], restart: :temporary)
    ], strategy: :simple_one_for_one)
  end
end
