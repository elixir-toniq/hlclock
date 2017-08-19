defmodule Hlc.Mixfile do
  use Mix.Project

  @version "0.1.0"

  def project do
    [app: :hlclock,
     version: @version,
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     description: description(),
     package: package(),
     deps: deps(),
     name: "HLClock",
     source_url: "https://github.com/keathley/hlclock",
   ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [extra_applications: [:logger]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:my_dep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:my_dep, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:stream_data, "~> 0.1.1", only: [:test, :dev]},
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
      files: ["lib", "mix.exs", "README.md", "LICENSE"],
      maintainers: ["Chris Keathley", "Neil Menne"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/keathley/hlclock"},
    ]
  end
end
