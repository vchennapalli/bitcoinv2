# Referred and obtained from
# http://www.petecorey.com/blog/2018/01/08/bitcoins-base58check-in-pure-elixir/

defmodule Base58 do
  @moduledoc """
  module to encode data into Base58 format
  """

  @alphabet '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz'

  @doc """
  encode given data into Base58 format
  """
  def encode(data, hash \\ "")
  def encode(data, hash) when is_binary(data) do
    encode_zeros(data) <> encode(:binary.decode_unsigned(data), hash)
  end

  def encode(0, hash), do: hash

  def encode(data, hash) do
    character = <<Enum.at(@alphabet, rem(data, 58))>>
    encode(div(data, 58), character <> hash)
  end


  # calculates number of leading zero bytes
  defp leading_zeros(data) do
    :binary.bin_to_list(data)
    |> Enum.find_index(&(&1 != 0))
  end

  # encodes those leading zeros accordingly
  defp encode_zeros(data) do
    <<Enum.at(@alphabet, 0)>>
    |> String.duplicate(leading_zeros(data))
  end

end
