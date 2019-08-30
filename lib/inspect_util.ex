defmodule SumMag.Opt do
  @syntax_colors [atom: :cyan, number: :yellow]

  def inspect(term) do
    term
    |> IO.inspect(syntax_colors: @syntax_colors)
  end

  def inspect(term, label: label) when is_binary(label) do
    term
    |> IO.inspect([syntax_colors: @syntax_colors, label: label])

    term
  end

  def debug(term) do
    term
    |> SumMag.Opt.inspect(label: "debug")
    :timer.sleep(100)
    term
  end
end