# defmodule Hastega.Imports do
#   # use Constants

#   @moduledoc """
#   Documentation for Hastega.Imports.
#   Currently, it provides the following:

#   * `is_int64` macro that can be used in `when` clauses to judge that a value is within INT64.
#   * `is_uint64` macro that can be used in `when` clauses to judge that a value is within UINT64.
#   * `is_bignum` macro that can be used in `when` clauses to judge that a value needs BigNum representation, that is, it is an integer but not within INT64 nor UINT64.
#   * `max_int` is the constant value of maxium of INT64.
#   * `min_int` is the constant value of minimum of INT64.
#   * `max_uint` is the constant value of maxium of UINT64.
#   * `min_uint` is the constant value of minimum of UINT64.
#   """

#   @name :max_int
#   @value 0x7fff_ffff_ffff_ffff

#   @name :min_int
#   @value -0x8000_0000_0000_0000

#   @name :max_uint
#   @value 0xffff_ffff_ffff_ffff

#   @name :min_uint
#   @value 0

#   @doc """
#   is_int64(value) returns true if the value is a signed integer, equals or is less than max_int and equals or is greater than min_int.
#   """
#   defmacro is_int64(value) do
#     quote do
#       is_integer(unquote(value))
#       and unquote(value) <= unquote(Hastega.Imports.max_int)
#       and unquote(value) >= unquote(Hastega.Imports.min_int)
#     end
#   end

#   @doc """
#   is_uint64(value) returns true if the value is an unsigned integer, equals or is less than max_uint and equals or is greater than min_uint.
#   """
#   defmacro is_uint64(value) do
#     quote do
#       is_integer(unquote(value))
#       and unquote(value) <= unquote(Hastega.Imports.max_uint)
#       and unquote(value) >= unquote(Hastega.Imports.min_uint)
#     end
#   end

#   @doc """
#   is_bignum(value) returns true if the value is an integer but larger than max_uint and smaller than min_int.
#   """
#   defmacro is_bignum(value) do
#     quote do
#       is_integer(unquote(value))
#       and (unquote(value) > unquote(Hastega.Imports.max_uint)
#       or unquote(value) < unquote(Hastega.Imports.min_int))
#     end
#   end
# end