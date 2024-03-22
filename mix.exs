defmodule ExRTCP.MixProject do
  use Mix.Project

  @version "0.2.0"
  @source_url "https://github.com/elixir-webrtc/ex_rtcp"

  def project do
    [
      app: :ex_rtcp,
      version: @version,
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      description: "Implementation of the RTCP protocol",
      package: package(),
      deps: deps(),

      # docs
      docs: docs(),
      source_url: @source_url,

      # dialyzer
      dialyzer: [
        plt_local_path: "_dialyzer",
        plt_core_path: "_dialyzer"
      ],

      # code coverage
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        "coveralls.json": :test
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  def package do
    [
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => @source_url}
    ]
  end

  defp deps do
    [
      {:excoveralls, "~> 0.14", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}
    ]
  end

  defp docs() do
    [
      main: "readme",
      extras: ["README.md"],
      source_ref: "v#{@version}",
      formatters: ["html"],
      nest_modules_by_prefix: [
        ExRTCP.Packet,
        ExRTCP.Packet.TransportFeedback,
        ExRTCP.Packet.PayloadFeedback
      ],
      groups_for_modules: [
        "Transport layer feedbacks": ~r/ExRTCP\.Packet\.TransportFeedback/,
        "Payload-specific feedbacks": ~r/ExRTCP\.Packet\.PayloadFeedback/,
        "Original (RFC 3550)": ~r/ExRTCP\.Packet\./
      ]
    ]
  end
end
