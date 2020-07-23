defmodule ExPlasma.Transaction.SignedTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias ExPlasma.PaymentV1Builder
  alias ExPlasma.Support.TestEntity
  alias ExPlasma.Transaction
  alias ExPlasma.Transaction.Signed
  alias ExPlasma.Transaction.Type.PaymentV1

  @alice TestEntity.alice()
  @bob TestEntity.bob()
  @eth <<0::160>>

  setup_all do
    %{priv_encoded: alice_priv, addr: alice_addr} = @alice
    %{addr: bob_addr} = @bob

    signed =
      PaymentV1Builder.new()
      |> PaymentV1Builder.add_input(blknum: 1, txindex: 0, oindex: 0, position: 1_000_000_000)
      |> PaymentV1Builder.add_input(blknum: 2, txindex: 0, oindex: 0, position: 2_000_000_000)
      |> PaymentV1Builder.add_output(output_guard: bob_addr, token: @eth, amount: 12)
      |> PaymentV1Builder.sign!(keys: [alice_priv, alice_priv])

    encoded_signed_tx = Transaction.encode(signed)

    {:ok,
     %{
       alice_addr: alice_addr,
       signed: signed,
       encoded_signed_tx: encoded_signed_tx
     }}
  end

  describe "encode/1" do
    test "encodes a signed transaction into an RLP encoded binary", %{signed: signed} do
      encoded = Signed.encode(signed)

      assert is_binary(encoded)
      assert {:ok, decoded} = Signed.decode(encoded)
      assert decoded == signed
    end
  end

  describe "to_rlp/1" do
    test "returns the RLP list of a signed transaction", %{signed: signed} do
      rlp = Signed.to_rlp(signed)

      assert [sigs, tx_type, inputs, outputs, tx_data, metadata] = rlp

      assert sigs == signed.sigs
      assert is_binary(tx_type)
      assert is_list(inputs)
      assert is_list(outputs)
      assert is_binary(tx_data)
      assert is_binary(metadata)
    end
  end

  describe "decode/1" do
    test "returns `{:ok, signed}` when given valid rlp bytes", %{encoded_signed_tx: encoded_signed_tx, signed: signed} do
      assert {:ok, decoded} = Signed.decode(encoded_signed_tx)
      assert decoded == signed
    end

    test "returns a malformed_rlp error when rlp is not decodable", %{encoded_signed_tx: encoded_signed_tx} do
      assert Signed.decode("A" <> encoded_signed_tx) == {:error, :malformed_rlp}

      <<_, malformed_1::binary>> = encoded_signed_tx
      assert Signed.decode(malformed_1) == {:error, :malformed_rlp}

      cropped_size = byte_size(encoded_signed_tx) - 1
      <<malformed_2::binary-size(cropped_size), _::binary-size(1)>> = encoded_signed_tx
      assert Signed.decode(malformed_2) == {:error, :malformed_rlp}
    end
  end

  describe "to_map/1" do
    test "returns `{:ok, signed}` when given valid rlp list", %{signed: signed} do
      rlp = Signed.to_rlp(signed)

      assert {:ok, mapped} = Signed.to_map(rlp)
      assert mapped == signed
    end

    test "returns malformed_witnesses error when not given a list for the 1st arg", %{signed: signed} do
      malformed_rlp = signed |> Signed.to_rlp() |> List.replace_at(0, <<1>>)

      assert Signed.to_map(malformed_rlp) == {:error, :malformed_witnesses}
    end

    test "returns malformed_transaction error given rlp is invalid" do
      assert Signed.to_map(1) == {:error, :malformed_transaction}
    end
  end

  describe "validate/1" do
    test "returns :ok when the signed transaction is valid", %{signed: signed} do
      assert Signed.validate(signed) == :ok
    end

    test "returns malformed_witnesses when one of the sig is invalid", %{signed: signed} do
      [sig_1, _sig_2] = signed.sigs

      signed = %{signed | sigs: [sig_1, <<12>>]}
      assert Signed.validate(signed) == {:error, {:witnesses, :malformed_witnesses}}
    end

    test "forward validation to protocol" do
      %{priv_encoded: alice_priv} = @alice
      %{addr: bob_addr} = @bob

      signed =
        PaymentV1Builder.new()
        |> PaymentV1Builder.add_input(blknum: 1, txindex: 0, oindex: 0, position: 1_000_000_000)
        |> PaymentV1Builder.add_input(blknum: 1, txindex: 0, oindex: 0, position: 1_000_000_000)
        |> PaymentV1Builder.add_output(output_guard: bob_addr, token: @eth, amount: 12)
        |> PaymentV1Builder.sign!(keys: [alice_priv, alice_priv])

      assert Signed.validate(signed) == {:error, {:inputs, :duplicate_inputs}}
    end
  end

  describe "get_witnesses/1" do
    test "returns {:ok, addresses} when signatures are valid", %{signed: signed, alice_addr: alice_addr} do
      assert {:ok, witnesses} = Signed.get_witnesses(signed)
      assert witnesses == [alice_addr, alice_addr]
    end

    test "returns {:error, :corrupted_witness} when the signature is invalid" do
      signed = %Signed{raw_tx: %PaymentV1{}, sigs: [<<1>>]}

      assert Signed.get_witnesses(signed) == {:error, :corrupted_witness}
    end
  end
end
