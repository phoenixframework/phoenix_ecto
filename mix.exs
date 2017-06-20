defmodule PhoenixEcto.Mixfile do
  use Mix.Project

  @version "3.2.2"

  def project do
    [app: :phoenix_ecto,
     version: @version,
     elixir: "~> 1.3",
     deps: deps(),

     # Hex
     description: "Integration between Phoenix & Ecto",
     package: package(),

     # Docs
     name: "Phoenix/Ecto",
     docs: [main: "main",
            extras: ["README.md": [filename: "main", title: "Phoenix/Ecto"]]]]
  end

  def application do
    [applications: [:logger, :ecto, :plug]]
  end

  defp package do
    [maintainers: ["José Valim", "Chris Mccord"],
     licenses: ["Apache 2.0"],
     links: %{"GitHub" => "https://github.com/phoenixframework/phoenix_ecto"}]
  end

  defp deps do
    [{:phoenix_html, "~> 2.9", optional: true},
     {:ecto, "~> 2.1"},
     {:plug, "~> 1.0"},
     {:ex_doc, ">= 0.0.0", only: :dev}]
  end
end
