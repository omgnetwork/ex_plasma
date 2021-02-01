defmodule ExPlasma.Transaction.SignedTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias ExPlasma.Builder
  alias ExPlasma.Support.TestEntity
  alias ExPlasma.Transaction
  alias ExPlasma.Transaction.Signed
  alias ExPlasma.Transaction.TypeMapper

  @alice TestEntity.alice()
  @bob TestEntity.bob()
  @eth <<0::160>>
  @zero_metadata <<0::256>>
  @payment_tx_type TypeMapper.tx_type_for(:tx_payment_v1)

  setup_all do
    %{priv_encoded: alice_priv, addr: alice_addr} = @alice
    %{addr: bob_addr} = @bob

    signed =
      ExPlasma.payment_v1()
      |> Builder.new()
      |> Builder.add_input(blknum: 1, txindex: 0, oindex: 0, position: 1_000_000_000)
      |> Builder.add_input(blknum: 2, txindex: 0, oindex: 0, position: 2_000_000_000)
      |> Builder.add_output(output_guard: bob_addr, token: @eth, amount: 12)
      |> Builder.sign!([alice_priv, alice_priv])

    {:ok, encoded_signed_tx} = Transaction.encode(signed)

    {:ok,
     %{
       alice_addr: alice_addr,
       signed: signed,
       encoded_signed_tx: encoded_signed_tx
     }}
  end

  describe "decode/1" do
    test "successfuly decodes a signed transaction", %{encoded_signed_tx: encoded_signed_tx} do
      assert {:ok, [_sigs, _type, _inputs, _outputs, _data, _metadata]} = Signed.decode(encoded_signed_tx)
    end

    test "returns a malformed_rlp error when rlp is not decodable", %{encoded_signed_tx: encoded_signed_tx} do
      assert Signed.decode("A" <> encoded_signed_tx) == {:error, :malformed_rlp}

      <<_, malformed_1::binary>> = encoded_signed_tx
      assert Signed.decode(malformed_1) == {:error, :malformed_rlp}

      cropped_size = byte_size(encoded_signed_tx) - 1
      <<malformed_2::binary-size(cropped_size), _::binary-size(1)>> = encoded_signed_tx
      assert Signed.decode(malformed_2) == {:error, :malformed_rlp}
    end

    test "returns a malformed_transaction error when rlp is decodable, but doesn't represent a known transaction format" do
      assert Signed.decode(<<192>>) == {:error, :malformed_transaction}
      assert Signed.decode(<<0x80>>) == {:error, :malformed_transaction}
      assert Signed.decode(<<>>) == {:error, :malformed_transaction}
      assert Signed.decode(ExRLP.encode(23)) == {:error, :malformed_transaction}
    end

    test "returns a malformed_witnesses error when given something else than a list for witnesses" do
      assert Signed.decode(ExRLP.encode([<<1>>, @payment_tx_type, [], [], 0, @zero_metadata])) ==
               {:error, :malformed_witnesses}
    end
  end

  describe "validate/1" do
    test "returns :ok when the signatures are valid", %{signed: signed} do
      assert Signed.validate(signed) == :ok
    end

    test "returns a malformed_witness error when not given list of valid length binary for sigs", %{
      signed: signed
    } do
      error = {:error, {:witnesses, :malformed_witnesses}}

      assert Signed.validate(%Transaction{signed | sigs: [[1], [2]]}) == error
      assert Signed.validate(%Transaction{signed | sigs: [[1, 2]]}) == error
      assert Signed.validate(%Transaction{signed | sigs: [1, 2]}) == error
      assert Signed.validate(%Transaction{signed | sigs: [<<1>>, <<1>>]}) == error
    end
  end

  describe "get_witnesses/1" do
    test "returns {:ok, addresses} when signatures are valid", %{signed: signed, alice_addr: alice_addr} do
      assert {:ok, witnesses} = Signed.get_witnesses(signed)
      assert witnesses == [alice_addr, alice_addr]
    end

    test "returns a corrupted_witness error when given a list containing a malformed witness", %{
      signed: signed
    } do
      [sig_1, sig_2] = signed.sigs
      error = {:error, :corrupted_witness}

      assert Transaction.with_witnesses(%{signed | sigs: [<<1>>, <<1>>]}) == error
      assert Transaction.with_witnesses(%{signed | sigs: [sig_1, <<1::size(520)>>]}) == error
      assert Transaction.with_witnesses(%{signed | sigs: [<<1::size(520)>>, sig_2]}) == error
    end
  end

  describe "compute_signatures/2" do
    test "returns {:ok, sigs} when given valid keys" do
      %{priv_encoded: key_1} = @alice
      %{priv_encoded: key_2} = @bob

      tx =
        ExPlasma.payment_v1()
        |> Builder.new()
        |> Builder.add_input(blknum: 1, txindex: 0, oindex: 0, position: 1_000_000_000)
        |> Builder.add_input(blknum: 2, txindex: 0, oindex: 0, position: 2_000_000_000)
        |> Builder.add_input(blknum: 3, txindex: 0, oindex: 0, position: 3_000_000_000)

      assert {:ok, [_sig_1, _sig_2, _sig_3]} = Signed.compute_signatures(tx, [key_1, key_1, key_2])
    end

    test "returns {:error, :not_signable} when given an invalid struct" do
      %{priv_encoded: key_1} = @alice
      %{priv_encoded: key_2} = @bob

      assert Signed.compute_signatures(%{}, [key_1, key_1, key_2]) == {:error, :not_signable}
    end
  end
end
