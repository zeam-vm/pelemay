defmodule Mix.Tasks.Compile.Pelemay do
  use Mix.Task.Compiler

  def run(__args) do
  	Mix.target(:compile)
  	:ok
  end
end