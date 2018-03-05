defmodule HLClock.Mixfile do
  use Mix.Project

  @version "0.1.6"

  def project do
    [app: :hlclock,
     version: @version,
     elixir: "~> 1.5",
     elixirc_paths: elixirc_paths(Mix.env),
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     description: description(),
     package: package(),
     deps: deps(),
     name: "HLClock",
     source_url: "https://github.com/toniqsystems/hlclock",
   ]
  end

  def application do
    [
      mod: {HLClock.Application, []},
      extra_applications: [:logger]
    ]
  end

  def elixirc_paths(:test), do: ["lib", "test/support"]
  def elixirc_paths(:dev), do: ["lib", "test/support/generators.ex"]
  def elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:stream_data, "~> 0.2", only: [:test, :dev]},
      {:ex_doc, "~> 0.16", only: :dev},
    ]
  end

  defp description do
    """
    Hybrid Logical Clocks.
    """
  end

  defp package do
    [
      name: :hlclock,
      files: ["lib", "mix.exs", "README.md"],
      maintainers: ["Chris Keathley", "Neil Menne"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => "https://github.com/toniqsystems/hlclock"},
    ]
  end
end
