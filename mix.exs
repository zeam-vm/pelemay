defmodule Pelemay.MixProject do
  use Mix.Project

  def project do
    [
      app: :pelemay,
      version: "0.0.10",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      docs: [
        api_reference: false,
        main: "Pelemay"
      ],
      elixirc_paths: elixirc_paths(Mix.env())
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
      {:cpu_info, "~> 0.2.1"},
      {:ring_logger, "~> 0.6"},

      # Docs dependencies
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:mix_test_watch, "~> 1.0", only: :dev, runtime: false}
    ]
  end

  defp description() do
    "Pelemay = The Penta (Five) “Elemental Way”: Freedom, Insight, Beauty, Efficiency and Robustness"
  end

  defp package() do
    [
      name: "pelemay",
      maintainers: [
        "Susumu Yamazaki",
        "Masakazu Mori",
        "Yoshihiro Ueno",
        "Hideki Takase",
        "Yuki Hisae"
      ],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => "https://github.com/zeam-vm/pelemay"},
      files: [
        # These are the default files
        "lib",
        "LICENSE.txt",
        "mix.exs",
        "README.md"
      ]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
