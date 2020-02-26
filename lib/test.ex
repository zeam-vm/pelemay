defmodule Test do
  import Pelemay_CL

    defpelemaycl do
        def twice_plus(list) do
            list 
            |> Enum.map(&(&1 * 2))
            |> Enum.map(&(&1 + 1))
        end

        def logistic_map(list) do
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

        def list_minus_2(list) do
            list
            |> Enum.map(&(&1 - 2))
        end

        def list_plus_2(list) do
            list
            |> Enum.map(fn x -> x + 2 end)
        end

        def list_mult_2(list) do
            list
            |> Enum.map(fn x -> x * 2 end)
        end

        def list_div_2(list) do
            list
            |> Enum.map(&(&1 / 2))
        end

        def list_mod_2(list) do
            list |> Enum.map(&rem(&1, 2))
        end

        def list_triangle(list) do
            list |> Enum.map(&(&1 * &1))
            |> Enum.map(&(&1 * &1))
        end

    end

end