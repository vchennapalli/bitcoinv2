defmodule KeyGenerator do
  alias Helper, as: H
  @moduledoc """
  generates a private key, public key and public address
  """
  @upbound :binary.decode_unsigned(<<
  0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
  0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFE,
  0xBA, 0xAE, 0xDC, 0xE6, 0xAF, 0x48, 0xA0, 0x3B,
  0xBF, 0xD2, 0x5E, 0x8C, 0xD0, 0x36, 0x41, 0x41
  >>)

  @doc """
  generates a new triplet of private and public keys and public address
  """
  def everything() do
    private_key = generate_private_key()
    public_key = generate_public_key(private_key)
    public_address = public_key |> generate_public_hash() |> generate_public_address()

    private_key = private_key |> :binary.encode_unsigned()

    {private_key, public_key, public_address}
  end


  @doc """
  generates a private key in unsigned int format
  """
  def generate_private_key do
    private_key = :crypto.strong_rand_bytes(32) |> :binary.decode_unsigned

    if validate(private_key) == false do
      generate_private_key()
    else
      private_key
    end
  end

  defp validate(key) do
    key > 1 and key < @upbound
  end

  @doc """
  generates public key in binary format
  """
  def generate_public_key(private_key) do
    :crypto.generate_key(:ecdh, :crypto.ec_curve(:secp256k1), private_key)
    |> elem(0)
  end


  @doc """
  generates public hash of public key
  """
  def generate_public_hash(public_key) do
    public_key
    |> H.hash(:sha256)
    |> H.hash(:ripemd160)
  end

  @doc """
  generates public address to receive transactions
  """
  def generate_public_address(public_hash, version \\ <<0x00>>) do
    public_hash
    |> Base58Check.encode(version)
  end

end


