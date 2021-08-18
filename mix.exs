defmodule PhoenixEcto.Mixfile do
  use Mix.Project

  @source_url "https://github.com/phoenixframework/phoenix_ecto"
  @version "4.4.0"

  def project do
    [
      app: :phoenix_ecto,
      version: @version,
      elixir: "~> 1.7",
      deps: deps(),

      # Hex
      description: "Integration between Phoenix & Ecto",
      package: package(),

      # Docs
      name: "Phoenix/Ecto",
      docs: [
        main: "main",
        extras: ["README.md": [filename: "main", title: "Phoenix/Ecto"]],
        source_ref: "v#{@version}",
        source_url: @source_url
      ],
      xref: [
        exclude: [
          {Ecto.Migrator, :migrations, 1},
          {Ecto.Migrator, :run, 3}
        ]
      ]
    ]
  end

  def application do
    [
      mod: {Phoenix.Ecto, []},
      extra_applications: [:logger],
      env: [exclude_ecto_exceptions_from_plug: []]
    ]
  end

  defp package do
    [
      maintainers: ["José Valim", "Chris Mccord"],
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url}
    ]
  end

  defp deps do
    [
      {:phoenix_html, "~> 2.14.2 or ~> 3.0", optional: true},
      {:ecto, "~> 3.3"},
      {:plug, "~> 1.9"},
      {:ex_doc, ">= 0.0.0", only: :docs}
    ]
  end
end
