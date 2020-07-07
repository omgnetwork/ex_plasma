defmodule ExPlasma.CryptoTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias ExPlasma.Crypto
  alias ExPlasma.Encoding
  alias ExPlasma.Signature

  describe "recover_address/2" do
    test "recovers address of the signer from a binary-encoded signature" do
      {:ok, priv} = generate_private_key()
      {:ok, pub} = generate_public_key(priv)
      {:ok, address} = Crypto.generate_address(pub)

      msg = :crypto.strong_rand_bytes(32)
      sig = Signature.signature_digest(msg, Encoding.to_hex(priv))

      assert {:ok, ^address} = Crypto.recover_address(msg, sig)
    end
  end

  describe "generate_address/1" do
    test "generates an address with SHA3" do
      # test vectors below were generated using pyethereum's sha3 and privtoaddr
      py_priv = "7880aec93413f117ef14bd4e6d130875ab2c7d7d55a064fac3c2f7bd51516380"
      py_pub = "c4d178249d840f548b09ad8269e8a3165ce2c170"
      priv = Encoding.keccak_hash(<<"11">>)

      {:ok, pub} = generate_public_key(priv)
      {:ok, address} = Crypto.generate_address(pub)
      {:ok, decoded_private} = Base.decode16(py_priv, case: :lower)
      {:ok, decoded_address} = Base.decode16(py_pub, case: :lower)

      assert ^decoded_private = priv
      assert ^address = decoded_address
    end

    test "generates an address with a public signature" do
      # test vector was generated using plasma.utils.utils.sign/2 from plasma-mvp
      py_signature =
        "b8670d619701733e1b4d10149bc90eb4eb276760d2f77a08a5428d4cbf2eadbd656f374c187b1ac80ce31d8c62076af26150e52ef1f33bfc07c6d244da7ca38c1c"

      msg = Encoding.keccak_hash("1234")
      priv = Encoding.keccak_hash("11")

      {:ok, pub} = generate_public_key(priv)
      {:ok, _} = Crypto.generate_address(pub)

      sig = Signature.signature_digest(msg, Encoding.to_hex(priv))
      assert ^sig = Base.decode16!(py_signature, case: :lower)
    end
  end

  defp generate_private_key(), do: {:ok, :crypto.strong_rand_bytes(32)}

  defp generate_public_key(<<priv::binary-size(32)>>) do
    {:ok, der_pub} = get_public_key(priv)
    {:ok, der_to_raw(der_pub)}
  end

  defp der_to_raw(<<4::integer-size(8), data::binary>>), do: data

  defp get_public_key(private_key) do
    case :libsecp256k1.ec_pubkey_create(private_key, :uncompressed) do
      {:ok, public_key} -> {:ok, public_key}
      {:error, reason} -> {:error, to_string(reason)}
    end
  end
end
