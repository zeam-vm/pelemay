defmodule Pelemay.Logger do
  @behaviour :gen_event
  @format "$date $time [$level] $message"

  require Logger

  def init(__MODULE__) do
    {:ok, %{path: nil, format: @format}}
  end

  def init(__MODULE__, path) do
    {:ok, %{path: path, format: @format}}
  end

  def handle_call({:configure, opts}, state) do
    path = Keyword.get(opts, :path, state.path)
    format = Keyword.get(opts, :format, state.format)
    new_state = %{state | path: path, format: format}
    {:ok, {:ok, new_state}, new_state}
  end

  def handle_event({level, _group_leader, {Logger, message, timestamp, metadata}}, state) do
    unless is_nil(state.path) do
      state.path |> Path.dirname() |> File.mkdir_p()
    end

    log_line =
      Logger.Formatter.format(
        Logger.Formatter.compile(state.format),
        level,
        message,
        timestamp,
        metadata
      )

    :ok = File.write!(state.path, "#{log_line}\n", [:append])

    {:ok, state}
  end

  def handle_event(:flush, state) do
    {:ok, state}
  end

  def handle_info({:io_reply, _, :ok}, state) do
    {:ok, state}
  end
end
