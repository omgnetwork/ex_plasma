defmodule ExPlasma.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_plasma,
      version: "0.1.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
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

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      applications: [:ethereumex],
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, "~> 1.2.2", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0.0-rc.7", only: [:dev], runtime: false},
      {:ethereumex, "~> 0.6.0"},
      {:telemetry, "~> 0.4.1"},
      {:ex_abi, "~> 0.5.1"},
      {:ex_rlp, "~> 0.5.3"},
      {:ex_secp256k1, "~> 0.1.2"},
      {:exvcr, "~> 0.10", only: :test},
      {:merkle_tree, "~> 2.0.0"},
      {:stream_data, "~>0.4.3", only: :test},
      {:excoveralls, "~> 0.10", only: :test}
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
      :merkle_tree
    ]
end
