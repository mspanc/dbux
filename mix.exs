defmodule Dbux.Mixfile do
  use Mix.Project

  def project do
    [app: :dbux,
     version: "0.0.1",
     elixir: "~> 1.0",
     description: description,
     package: package,
     deps: deps]
  end

  def application do
    []
  end

  defp deps do
    [{:connection, "~> 1.0.2"}]
  end

  defp description do
    """
    D-Bus IPC protocol for Elixir.
    """
  end

  defp package do
    [# These are the default files included in the package
     files: ["lib", "priv", "mix.exs", "README*", "readme*", "LICENSE*", "license*"],
     maintainers: ["Marcin Lewandowski"],
     licenses: ["MIT"],
     links: %{"GitHub" => "https://github.com/mspanc/dbux",
              "Docs" => "http://mspanc.github.io/dbux/"}]
  end
end
