defmodule Phoenix.Ecto do
  @moduledoc """
  Integrates Phoenix with Ecto.

  It implements many protocols that makes it easier to use
  Ecto with Phoenix either when working with HTML or JSON.
  """
  use Application
  import Supervisor.Spec

  def start(_type, _args) do
    Supervisor.start_link([
      supervisor(Phoenix.Ecto.SQL.SandboxSupervisor, [])
    ], strategy: :one_for_one, name: Phoenix.Ecto.Supervisor)
  end
end
