# Referred and obtained from
# http://www.petecorey.com/blog/2018/01/08/bitcoins-base58check-in-pure-elixir/

defmodule Base58Check do

  @moduledoc """
  Base58 + Checksum
  """

  @doc """
  returns Base58
  """
  def encode(data, version \\ <<0x00>>) do
    version <> data <> checksum(version, data)
    |> Base58.encode
  end


  @doc """
  returns first four bytes of the hashed value
  """
  def checksum(version, data) do
    version <> data
    |> sha256
    |> sha256
    |> split
  end

  defp split(<< hash :: bytes-size(4), _ :: bits >>), do: hash

  defp sha256(data), do: :crypto.hash(:sha256, data)

end
