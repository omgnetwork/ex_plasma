defmodule ExPlasma.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_plasma,
      version: "0.2.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      description: description(),
      deps: deps(),
      package: package(),
      name: "ExPlasma",
      docs: docs(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      dialyzer: dialyzer()
    ]
  end

  defp description do
    """
    A library for encoding, decoding and validating transactions used for the OMG Network Plasma contracts.
    """
  end

  defp package do
    [
      name: :ex_plasma,
      maintainers: ["OMG Network team"],
      licenses: ["Apache-2.0 License"],
      links: %{"GitHub" => "https://github.com/omgnetwork/ex_plasma"}
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: [
        "README.md"
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      applications: [],
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, "~> 1.4", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:ethereumex, "~> 0.6.0", only: [:test]},
      {:ex_abi, "~> 0.4.0"},
      {:ex_rlp, "~> 0.5.3"},
      {:excoveralls, "~> 0.10", only: [:test]},
      {:exth_crypto, "~> 0.1.6"},
      {:libsecp256k1, git: "https://github.com/omisego/libsecp256k1.git", branch: "elixir-only", override: true},
      {:merkle_tree, "~> 2.0.0"},
      {:stream_data, "~>0.4.3", only: [:test]},
      {:telemetry, "~> 0.4", only: [:test]}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end

  defp dialyzer do
    [
      flags: [:error_handling, :race_conditions, :underspecs, :unknown, :unmatched_returns],
      ignore_warnings: "dialyzer.ignore-warnings",
      list_unused_filters: true,
      plt_add_apps: plt_apps()
    ]
  end

  defp plt_apps,
    do: [
      :ex_abi,
      :ex_rlp,
      :exth_crypto,
      :merkle_tree,
      :libsecp256k1
    ]
end
