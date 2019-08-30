defmodule Hastega.MixProject do
  use Mix.Project

  def project do
    [
      app: :pelemay,
      version: "0.0.0",
      elixir: "~> 1.6",
      compilers: Mix.compilers() ++ [:native],
      start_permanent: Mix.env() == :prod,
      description: description(),
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
      { :flow, "~> 0.14.3" },
      { :constants,   "~> 0.1.0" },
      # { :sum_mag,     "~> 0.0.9" },
      { :ex_doc,      ">= 0.0.0", only: :dev},
      { :benchfella, "~> 0.3.5" },
    ]
  end

  defp description() do
    "Pelemay = The Penta (Five) “Elemental Way”: Freedom, Insight, Beauty, Efficiency and Robustness"
  end

  defp package() do
    [
      name: "pelemay",
      maintainers: ["Susumu Yamazaki", "Masakazu Mori", "Yoshihiro Ueno", "Hideki Takase", "Yuki Hisae"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => "https://github.com/zeam-vm/pelemay"}
    ]
  end
end
