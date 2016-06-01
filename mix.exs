defmodule DBux.Mixfile do
  use Mix.Project

  def project do
    [app: :dbux,
     version: "1.0.3",
     elixir: "~> 1.0",
     description: description,
     package: package,
     test_coverage: [tool: ExCoveralls, test_task: "espec"],
     preferred_cli_env: [espec: :test, "coveralls": :test, "coveralls.detail": :test, "coveralls.post": :test, "coveralls.html": :test],
     deps: deps]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [{:connection, "~> 1.0.2"},
     {:ex_doc, ">= 0.0.0", only: :dev},
     {:earmark, ">= 0.0.0", only: :dev},
     {:espec, "~> 0.8.21", only: :test},
     {:excoveralls, "~> 0.5", only: :test}]
  end

  defp description do
    """
    Bindings for the D-Bus IPC protocol.
    """
  end

  defp package do
    [# These are the default files included in the package
     files: ["lib", "mix.exs", "README*"],
     maintainers: ["Marcin Lewandowski"],
     licenses: ["MIT"],
     links: %{"GitHub" => "https://github.com/mspanc/dbux"}]
  end
end
