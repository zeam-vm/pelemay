defmodule Pelemay.Zeam do
  import NimbleParsec

  defcombinatorp(
    :include,
    ignore(string("#"))
    |> concat(string("include"))
    |> ignore(repeat(ascii_char([?\s])))
    |> concat(
      choice([
        string("<")
        |> ascii_string([?a..?z, ?A..?Z, ?0..?9, ?_, ?.], min: 1)
        |> string(">"),
        string("\"")
        |> ascii_string([?a..?z, ?A..?Z, ?0..?9, ?_, ?.], min: 1)
        |> string("\"")
      ])
    )
    |> post_traverse(:match_and_emit_include)
  )

  defp match_and_emit_include(_rest, [">", header, "<", "include"], context, _line, _offset) do
    {[{:include, [], header}], context}
  end

  defp match_and_emit_include(_rest, ["\"", header, "\"", "include"], context, _line, _offset) do
    {[{:include_cd, [], header}], context}
  end

  defparsec(:clang, parsec(:include))

  @doc """
    ## Examples

    iex> Pelemay.Zeam.map_to_zeam_ir(["#include <stdio.h>"]) |> Enum.to_list
    [{:include, [], "stdio.h"}]
  """
  def map_to_zeam_ir(c_src_stream) do
    c_src_stream
    |> Stream.map(&String.trim/1)
    |> Stream.map(&to_zeam_ir/1)
  end

  defp to_zeam_ir(str) do
    {:ok, [result], "", %{}, _, _} = clang(str)
    result
  end

  @doc """
  	## Examples
  	```
  	["#include <stdio.h>"]
  	|> Pelemay.Zeam.write("/path/to/file")
  	```
  """
  def write(c_src_stream, path) do
    c_src_stream
    |> Stream.into(File.stream!(path), &"#{&1}\n")
    |> Stream.run()
  end

  @doc """
    ## Examples

    iex> Pelemay.Zeam.map_to_clang([{:include, [], "stdio.h"}]) |> Enum.to_list
    ["#include <stdio.h>"]
  """
  def map_to_clang(zeam_ir_stream) do
    zeam_ir_stream
    |> Stream.map(&to_clang/1)
  end

  defp to_clang({:include, _env, header}) do
    "#include <#{header}>"
  end

  defp to_clang({:include_cd, _env, header}) do
    "#include \"#{header}\""
  end
end
