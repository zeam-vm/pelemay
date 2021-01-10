defmodule Sample do
  import Pelemay
  require Pelemay

  @string """
  abcdefghi
  FizzBuzzFizzBuzz
  """
  @pattern "a"
  @replacement "A"

  def logistic_map_10_enum(list) do
    list
    |> Enum.map(&rem(22 * &1 * (&1 + 1), 6_700_417))
    |> Enum.map(&rem(22 * &1 * (&1 + 1), 6_700_417))
    |> Enum.map(&rem(22 * &1 * (&1 + 1), 6_700_417))
    |> Enum.map(&rem(22 * &1 * (&1 + 1), 6_700_417))
    |> Enum.map(&rem(22 * &1 * (&1 + 1), 6_700_417))
    |> Enum.map(&rem(22 * &1 * (&1 + 1), 6_700_417))
    |> Enum.map(&rem(22 * &1 * (&1 + 1), 6_700_417))
    |> Enum.map(&rem(22 * &1 * (&1 + 1), 6_700_417))
    |> Enum.map(&rem(22 * &1 * (&1 + 1), 6_700_417))
    |> Enum.map(&rem(22 * &1 * (&1 + 1), 6_700_417))
  end

  defpelemay do
    def list_square(list) when is_list(list) do
      list
      |> Enum.map(&(&1 * &1))
    end

    def list_square_fn(list) when is_list(list) do
      list
      |> Enum.map(fn x -> x * x end)
    end

    def list_plus1(list) do
      list
      |> Enum.map(&(&1 + 1))
    end

    def list_plus1_mult2(list) do
      list
      |> Enum.map(&(&1 + 1))
      |> Enum.map(&(&1 * 2))
    end

    def logistic_map_10_pelemay(list) do
      list
      |> Enum.map(&rem(22 * &1 * (&1 + 1), 6_700_417))
      |> Enum.map(&rem(22 * &1 * (&1 + 1), 6_700_417))
      |> Enum.map(&rem(22 * &1 * (&1 + 1), 6_700_417))
      |> Enum.map(&rem(22 * &1 * (&1 + 1), 6_700_417))
      |> Enum.map(&rem(22 * &1 * (&1 + 1), 6_700_417))
      |> Enum.map(&rem(22 * &1 * (&1 + 1), 6_700_417))
      |> Enum.map(&rem(22 * &1 * (&1 + 1), 6_700_417))
      |> Enum.map(&rem(22 * &1 * (&1 + 1), 6_700_417))
      |> Enum.map(&rem(22 * &1 * (&1 + 1), 6_700_417))
      |> Enum.map(&rem(22 * &1 * (&1 + 1), 6_700_417))
    end

    def list_chunk_by(list, num) do
      list
      |> Enum.chunk_by(num)
    end

    def list_chunk_every(list, num) do
      list
      |> Enum.chunk_every(num)
    end

    def list_reduce_sum(list) do
      list
      |> Enum.reduce(0, fn x, acc -> x + acc end)
    end

    def list_mult_sort(list) do
      list
      |> Enum.map(&(&1 * 2))
      |> Enum.sort(&(&1 >= &2))
    end

    def list_zip(a, b) do
      Enum.zip(a, b)
    end

    def replace_sample_c1(subject) do
      String.replace(subject, @pattern, @replacement)
    end

    def replace_sample_c2(subject) do
      subject |> String.replace(@pattern, @replacement)
    end

    def replace_sample_c3(subject, pattern, replacement) do
      String.replace(subject, pattern, replacement)
    end

    def string_replace_c4 do
      String.replace(@string, "Fizz", "Buzz")
    end

    def list_replace(subject, pattern, replacement) do
      subject
      |> Enum.map(&String.replace(&1, pattern, replacement))
    end

    def list_spilt do
      ["a, b"]
      |> Enum.map(&String.split(&1, ","))
    end
  end
end
