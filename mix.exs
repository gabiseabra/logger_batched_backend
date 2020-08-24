defmodule LoggerBatchedBackend.MixProject do
  use Mix.Project

  def project do
    [
      app: :logger_batched_backend,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      package: package(),
      deps: deps()
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
      {:mox, "~> 0.5", only: :test}
    ]
  end

  defp package() do
    [
      maintainers: ["Gabriela Seabra"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/gabiseabra/logger_batched_backend",
        "Logger" => "https://hexdocs.pm/logger/Logger.html"
      }
    ]
  end
end
