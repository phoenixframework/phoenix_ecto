defmodule PhoenixEcto.Mixfile do
  use Mix.Project

  @version "3.0.0"

  def project do
    [app: :phoenix_ecto,
     version: @version,
     elixir: "~> 1.2",
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
    [applications: [:logger, :ecto]]
  end

  defp package do
    [maintainers: ["José Valim", "Chris Mccord"],
     licenses: ["Apache 2.0"],
     links: %{"GitHub" => "https://github.com/phoenixframework/phoenix_ecto"}]
  end

  defp deps do
    [{:phoenix_html, "~> 2.6", optional: true},
     {:ecto, "~> 2.0.0-rc"}]
  end
end
