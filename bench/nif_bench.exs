# defmodule NifBench do
#   use Benchfella

  # @default_prime 6_700_417
  # @default_mu 22
  # @default_loop 10

  # @list_0x100     VecSample.range_to_list(1..0x100)
  # @list_0x1000    VecSample.range_to_list(1..0x1000)
  # @list_0x10000   VecSample.range_to_list(1..0x10000)
  # @list_0x100000  VecSample.range_to_list(1..0x100000)
  # @list_0x200000  VecSample.range_to_list(1..0x200000)
  # @chunk_list VecSample.chunk_every(@list_0x100, 4)

  # bench "Enum.map 0x100" do
  #   Enum.map(@list_0x100, & &1 * 2)
  # end

  # bench "nif_enum_map_mult_2 0x100" do
  #   VecSample.enum_map_mult_2(@list_0x100)
  # end

  # # bench "Enum.map 0x1000" do
  # #   Enum.map(@list_0x1000, & &1 * 2)
  # # end

  # bench "nif_enum_map_mult_2 0x1000" do
  #   VecSample.enum_map_mult_2(@list_0x1000)
  # end

  # # bench "Enum.map 0x10000" do
  # #   Enum.map(@list_0x10000, & &1 * 2)
  # # end

  # bench "enum_map_mult_2 0x10000" do
  #   VecSample.enum_map_mult_2(@list_0x10000)
  # end

  # bench "hastega enum_map 0x100" do
  #   HastegaSample.list_mult_2(@list_0x100)
  # end

  # bench "hastega enum_map 0x1000" do
  #   HastegaSample.list_mult_2(@list_0x1000)
  # end

  # bench "hastega enum_map 0x10000" do
  #   HastegaSample.list_mult_2(@list_0x10000)
  # end

  # bench "VecSample.chunk_every 0x100" do
  #   VecSample.chunk_every(@list_0x100, 4)
  # end

  # bench "Hastega.chunk_every 0x100" do
  #   HastegaSample.chunk_every(@list_0x100)
  # end

  # bench "Enum.chunk_every 0x100" do
  #   Enum.chunk_every(@list_0x100, 4)
  # end
# end