defmodule Pelemay.Db do
  # @on_load :init
  @table_name :nif_func
  alias SumMag.Opt

  @moduledoc """
  Documentation for Hastega.Generator.
  """
  def init do
    @table_name
    |> :ets.new([:set, :public, :named_table])

    @table_name
    |> :ets.insert({:func_num, 1})
  end

  def register(info) when 
    info |> is_map do

    id = get_func_num()
    key = generate_key(id)

    update()

    @table_name
    |> :ets.insert({key, info})
  end

  def validate(func_name) do
    registered = get_functions
    |> List.flatten
    
    case registered do
      [] -> nil
      other -> other 
      |> Enum.map(& Map.get(&1, :nif_name) == func_name)
      |> only_one?
    end
  end

  defp only_one?(list) do
    !Enum.find_value(list, false, & &1 == true)
  end

  def get_functions do
    num = get_func_num() - 1

    (1..num)
    |> Enum.map(& &1 |> get_function)
  end

  def get_function(id) do
    ret = @table_name
    |> :ets.match({generate_key(id), :"$1"})

    case ret do
      [] -> []
      other -> hd(other)
    end
  end

  def get_function([]), do: ""

  defp generate_key(id) do
    "function_#{id}" |> String.to_atom
  end

  defp get_func_num do
    [func_num: num] = @table_name |> :ets.lookup(:func_num)

    num
  end

  defp update do
    id = get_func_num()
    @table_name |> :ets.insert({:func_num, id+1})
  end 

  # def on_load do
  #   case :mnesia.start do
  #     :ok -> case :mnesia.create_table( :functions, [ attributes: [ :id, :module_name, :function_name, :is_public, :is_nif, :args, :do ] ] ) do
  #       {:atomic, :ok} -> :ok
  #       _ -> :err
  #     end
  #     _ -> :err
  #   end
  # end

  # def write_function({key, value}, module) do
  #   :mnesia.dirty_write({
  #     :functions,
  #     key,
  #     module,
  #     value[:function_name],
  #     value[:is_public],
  #     value[:is_nif],
  #     value[:args],
  #     value[:do]})
  # end

  # def read_function(id) do
  #   :mnesia.dirty_read({:functions, id})
  # end

  # def all_functions() do
  #   :mnesia.dirty_all_keys(:functions)
  # end

end