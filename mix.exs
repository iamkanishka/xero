defmodule Xero.MixProject do
  use Mix.Project

  @version "1.0.0"
  @source_url "https://github.com/iamkanishka/xero"
  @description "A complete, production-grade Elixir client for all 13 Xero APIs"

  def project do
    [
      app: :xero,
      version: @version,
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: @description,
      package: package(),
      docs: docs(),
      aliases: aliases(),
      dialyzer: dialyzer(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      elixirc_paths: elixirc_paths(Mix.env()),
      name: "Xero"
    ]
  end

  def application do
    [
      extra_applications: [:logger, :crypto],
      mod: {Xero.Application, []}
    ]
  end

  defp deps do
    [
      {:req, "~> 0.5 or ~> 0.6"},
      {:finch, "~> 0.18"},
      {:jason, "~> 1.4"},
      {:oauth2, "~> 2.0"},
      {:telemetry, "~> 1.2"},
      {:telemetry_metrics, "~> 0.6"},
      {:retry, "~> 0.18"},
      {:nimble_options, "~> 1.1"},
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.18", only: :test},
      {:bypass, "~> 2.1", only: :test},
      {:mox, "~> 1.1", only: :test},
      {:faker, "~> 0.17", only: :test}
    ]
  end

  defp package do
    [
      name: "xero",
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE CHANGELOG.md),
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "Changelog" => "#{@source_url}/blob/main/CHANGELOG.md",
        "Xero Developer Docs" => "https://developer.xero.com/documentation"
      },
      maintainers: ["iamkanishka"]
    ]
  end

  defp docs do
    [
      main: "readme",
      source_url: @source_url,
      source_ref: "v#{@version}",
      extras: ["README.md", "CHANGELOG.md", "guides/getting_started.md", "LICENSE"],
      groups_for_modules: [
        Core: [Xero, Xero.Config, Xero.Application],
        Auth: [Xero.Auth, Xero.Auth.TokenStore, Xero.Auth.Token],
        HTTP: [Xero.HTTP.Client, Xero.HTTP.RateLimiter],
        "Accounting API": ~r/Xero\.Accounting\..*/,
        "Assets API": [Xero.Assets],
        "BankFeeds API": [Xero.BankFeeds],
        "Files API": [Xero.Files],
        "Finance API": [Xero.Finance],
        "Projects API": [Xero.Projects],
        "Payroll AU": [Xero.Payroll.AU],
        "Payroll NZ": [Xero.Payroll.NZ],
        "Payroll UK": [Xero.Payroll.UK],
        "Practice Manager": [Xero.PracticeManager],
        "App Store": [Xero.AppStore],
        eInvoicing: [Xero.EInvoicing],
        Shared: [Xero.Types, Xero.Error, Xero.Paginator, Xero.Telemetry]
      ]
    ]
  end

  defp dialyzer do
    [
      plt_add_apps: [:mix, :ex_unit],
      plt_core_path: "priv/plts",
      plt_file: {:no_warn, "priv/plts/dialyzer.plt"},
      flags: [:error_handling, :underspecs],
      ignore_warnings: ".dialyzer_ignore.exs"
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "compile"],
      "test.all": ["test --cover"],
      lint: ["credo --strict", "dialyzer"],
      ci: ["compile --warnings-as-errors", "credo --strict", "test --cover"]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
