defmodule Pelemay.Db do
  # @on_load :init
  @table_name :nif_func
  @flags :flags
  @kernel :kernel

  @moduledoc """
  Documentation for Pelemay.Generator.
  """
  def init do
    @table_name
    |> :ets.new([:set, :public, :named_table])

    @table_name
    |> :ets.insert({:func_num, 1})

    @flags
    |> :ets.new([:set, :public, :named_table])

    @kernel
    |> :ets.new([:set, :public, :named_table])

    @kernel
    |> :ets.insert({:kernel, []})
  end

  def register(info)
      when info |> is_map do
    id = get_func_num()
    key = generate_key(id)

    update()

    @table_name
    |> :ets.insert({key, info})
  end

  def validate(func_name) do
    registered =
      get_functions()
      |> List.flatten()

    case registered do
      [] ->
        nil

      other ->
        other
        |> Enum.map(&(Map.get(&1, :nif_name) == func_name))
        |> only_one?
    end
  end

  def impl_validate(func_name) do
    get_functions()
    |> List.flatten()
    |> case do
      [] ->
        {:error, "DB is empty"}

      other ->
        other
        |> Enum.filter(&(Map.get(&1, :nif_name) == "#{func_name}"))
        |> hd
        |> Map.get(:impl)
    end
  end

  defp only_one?(list) do
    !Enum.find_value(list, false, &(&1 == true))
  end

  def get_functions do
    num = get_func_num() - 1

    1..num
    |> Enum.map(&(&1 |> get_function))
  end

  def get_function([]), do: ""

  def get_function(func_name) when is_bitstring(func_name) do
    get_functions()
    |> List.flatten()
    |> case do
      [] ->
        {:error, "DB is empty"}

      other ->
        other
        |> Enum.filter(&(Map.get(&1, :nif_name) == "#{func_name}"))
        |> hd
    end
  end

  def get_function(id) do
    ret =
      @table_name
      |> :ets.match({generate_key(id), :"$1"})

    case ret do
      [] -> []
      other -> hd(other)
    end
  end

  defp generate_key(id) do
    "function_#{id}" |> String.to_atom()
  end

  defp get_func_num do
    [func_num: num] = @table_name |> :ets.lookup(:func_num)

    num
  end

  defp update do
    id = get_func_num()
    @table_name |> :ets.insert({:func_num, id + 1})
  end

  def clear do
    :ets.delete_all_objects(@table_name)

    @table_name
    |> :ets.insert({:func_num, 1})
  end

  def set_flag(key, value) do
    @flags
    |> :ets.insert({key, value})
  end

  def get_flag(key) do
    @flags
    |> :ets.lookup(key)
    |> hd
    |> elem(1)
  end

  def get_kernels() do
    @kernel |> :ets.lookup(:kernel) |> hd |> elem(1)
  end

  def append_kernel(kernel_file) do
    @kernel
    |> :ets.insert({:kernel, get_kernels() ++ [kernel_file]})
  end
end
