defmodule Pelemay.Db do
  # @on_load :init
  @table_name :nif_func

  @moduledoc """
  Documentation for Pelemay.Generator.
  """
  def init do
    @table_name
    |> :ets.new([:set, :public, :named_table])

    @table_name
    |> :ets.insert({:func_num, 1})
  end

  def register(info)
      when info |> is_map do
    id = get_func_num()
    key = generate_key(id)
    arg_info = get_arg_info()
    regist_func_num(arg_info)
    update()

    @table_name
    |> :ets.insert({key, arg_info, info})
  end

  # register arg_name and which function information
  def regist_arg_info(info)
      when info |> is_atom do
    @table_name
    |> :ets.insert({:arg_name, info})

    @table_name
    |> :ets.insert({info, [], :args})
  end

  # get arg_name from ETS now registered
  def get_arg_info do
    registered = @table_name
    |> :ets.match({:arg_name, :"$1"})
    |> List.flatten()

    case registered do
      [] -> []
      other -> hd(other)
    end
  end

  # regist functions number to ETS which each module 
  def regist_func_num(arg_name)
      when arg_name |> is_atom do
    number_list =
      @table_name
      |> :ets.match({arg_name, :"$1", :args})
      |> List.flatten()

    updated_list = number_list ++ [get_func_num()]

    @table_name 
    |> :ets.update_element(arg_name, {2,updated_list}) 
  end

  #regist_func_num for same functions
  def regist_func_num(num)
      when num |> is_number do
    arg_name = get_arg_info()
    number_list =
      @table_name
      |> :ets.match({arg_name, :"$1", :args})
      |> List.flatten()

    updated_list = number_list ++ [num]

    @table_name 
    |> :ets.update_element(arg_name, {2,updated_list}) 
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

  # remake only_one? to identify index of functions when registered 
  defp only_one?(list) do
    case Enum.find_index(list, &(&1 == true)) do
      nil ->
        true
      other ->
        other + 1
    end
  end

  def get_functions do
    num = get_func_num() - 1

    1..num
    |> Enum.map(&(&1 |> get_function))
  end

  def get_arguments do
    @table_name
    |> :ets.match({:"$1", :"$2", :args})
  end

  def get_function([]), do: ""

  def get_function(id) do
    ret =
      @table_name
      |> :ets.match({generate_key(id), :_, :"$1"})

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
