defmodule ExPlasma.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_plasma,
      version: "0.1.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
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
      {:credo, "~> 1.1.0", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 0.5", only: [:dev], runtime: false},
      {:ethereumex, "~> 0.5.5"},
      {:ex_abi, "~> 0.2.0"},
      {:ex_rlp, "~> 0.5.2", override: true},
      {:exth_crypto, "~> 0.1.6"},
      {:exvcr, "~> 0.10", only: :test},
      {:libsecp256k1,
       git: "https://github.com/omisego/libsecp256k1.git", branch: "elixir-only", override: true},
      {:merkle_tree,
       git: "https://github.com/omisego/merkle_tree.git",
       branch: "prevent_second_preimage_attack",
       override: true},
      {:stream_data, "~>0.4.3", only: :test}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end

  defp dialyzer do
    [
      flags: [:error_handling, :race_conditions, :underspecs, :unknown, :unmatched_returns],
      ignore_warnings: "dialyzer.ignore-warnings",
      list_unused_filters: true
    ]
  end
end
