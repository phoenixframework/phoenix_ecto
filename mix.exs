defmodule PhoenixEcto.Mixfile do
  use Mix.Project

  @version "0.5.0"

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
    [applications: [:logger, :ecto]]
  end

  defp package do
    [contributors: ["José Valim"],
     licenses: ["Apache 2.0"],
     links: %{"GitHub" => "https://github.com/phoenixframework/phoenix_ecto"}]
  end

  defp deps do
    [{:phoenix_html, "~> 1.0", optional: true},
     {:poison, "~> 1.3", optional: true},
     {:ecto, "~> 0.12"}]
  end
end
