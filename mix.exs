defmodule PhoenixEcto.Mixfile do
  use Mix.Project

  @version "0.1.0"

  def project do
    [app: :phoenix_ecto,
     version: @version,
     elixir: "~> 1.0",
     deps: deps,

     # Hex
     description: "Integration between Phoenix & Ecto",
     package: package,

     # Docs
     name: "Phoenix/Ecto",
     docs: [source_ref: "v#{@version}",
            source_url: "https://github.com/phoenixframework/phoenix_ecto"]]
  end

  def application do
    [applications: [:logger, :ecto, :phoenix]]
  end

  defp package do
    [contributors: ["José Valim"],
     licenses: ["Apache 2.0"],
     links: %{"GitHub" => "https://github.com/phoenixframework/phoenix_ecto"}]
  end

  defp deps do
    # We are strict on Ecto requirement because
    # primary key functions are changing in the
    # next release.
    [{:phoenix, "~> 0.10-dev"},
     {:ecto, "~> 0.9.0"}]
  end
end
