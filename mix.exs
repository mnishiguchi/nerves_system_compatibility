defmodule NervesSystemsCompatibility.MixProject do
  use Mix.Project

  def project do
    [
      app: :nerves_systems_compatibility,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: dialyzer()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, "~> 1.0", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false},
      {:exvcr, "~> 0.11", only: :test},
      {:mix_test_watch, "~> 1.0", only: :dev, runtime: false},
      {:req, "~> 0.2"}
    ]
  end

  defp dialyzer() do
    [
      flags: [:missing_return, :extra_return, :unmatched_returns, :error_handling],
      plt_add_apps: [:mix]
    ]
  end
end
