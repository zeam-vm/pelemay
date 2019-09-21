defmodule PelemayTest.Sample do
  require Pelemay
  import Pelemay

  defpelemay do
    def map_square(list) do
      list |> Enum.map(&(&1 * &1))
    end
  end
end
