defmodule ExPlasma.TransactionTest do
  @moduledoc false
  use ExUnit.Case, async: true

  # doctest ExPlasma.Transaction

  alias ExPlasma.Crypto
  alias ExPlasma.Output
  alias ExPlasma.PaymentV1Builder
  alias ExPlasma.Transaction
  alias ExPlasma.Transaction.Protocol
  alias ExPlasma.Transaction.Signed
  alias ExPlasma.Transaction.Type.PaymentV1
  alias ExPlasma.Transaction.Recovered
  alias ExPlasma.Support.TestEntity

  @alice TestEntity.alice()
  @bob TestEntity.bob()
  @eth <<0::160>>

  describe "decode/2 with :raw mode" do
    test "successfuly decodes when given valid encoded raw transaction" do
      tx = PaymentV1.new([], [])
      encoded = tx |> Protocol.to_rlp() |> ExRLP.encode()

      assert {:ok, decoded} = Transaction.decode(encoded, :raw)
      assert decoded == tx
    end

    test "returns `malformed_rlp` when not given rlp binary" do
      assert {:error, :malformed_rlp} = Transaction.decode(123, :raw)
    end

    test "returns `unrecognized_transaction_type` when the given type is not supported" do
      encoded = ExRLP.encode([<<1337>>, <<0>>])
      assert {:error, :unrecognized_transaction_type} = Transaction.decode(encoded, :raw)
    end

    test "returns `malformed_transaction` when not given a valid raw transaction" do
      encoded = ExRLP.encode(<<0>>)
      assert {:error, :malformed_transaction} = Transaction.decode(encoded, :raw)
    end
  end

  describe "decode/2 with :recovered mode" do
    test "successfuly decodes when given valid encoded signed transaction" do
      %{priv_encoded: alice_priv} = @alice
      %{addr: bob_addr} = @bob

      signed =
        PaymentV1Builder.new()
        |> PaymentV1Builder.add_input(blknum: 1, txindex: 0, oindex: 0, position: 1_000_000_000)
        |> PaymentV1Builder.add_input(blknum: 2, txindex: 0, oindex: 0, position: 2_000_000_000)
        |> PaymentV1Builder.add_output(output_guard: bob_addr, token: @eth, amount: 12)
        |> PaymentV1Builder.sign!(keys: [alice_priv, alice_priv])

      encoded = signed |> Signed.to_rlp() |> ExRLP.encode()

      assert {:ok, %Recovered{} = decoded} = Transaction.decode(encoded, :recovered)
      assert decoded.signed_tx == signed
    end

    test "returns `malformed_rlp` when not given rlp binary" do
      assert {:error, :malformed_rlp} = Transaction.decode(123, :recovered)
    end

    test "returns `malformed_witnesses` when the given first item is not a list" do
      encoded = [<<1337>>, <<0>>] |> ExRLP.encode()
      assert {:error, :malformed_witnesses} = Transaction.decode(encoded, :recovered)
    end

    test "returns `malformed_transaction` when not given a valid raw transaction" do
      encoded = <<0>> |> ExRLP.encode()
      assert {:error, :malformed_transaction} = Transaction.decode(encoded, :recovered)
    end
  end

  describe "decode/2 with :signed mode" do
    test "successfuly decodes when given valid encoded signed transaction" do
      %{priv_encoded: alice_priv} = @alice
      %{addr: bob_addr} = @bob

      signed =
        PaymentV1Builder.new()
        |> PaymentV1Builder.add_input(blknum: 1, txindex: 0, oindex: 0, position: 1_000_000_000)
        |> PaymentV1Builder.add_input(blknum: 2, txindex: 0, oindex: 0, position: 2_000_000_000)
        |> PaymentV1Builder.add_output(output_guard: bob_addr, token: @eth, amount: 12)
        |> PaymentV1Builder.sign!(keys: [alice_priv, alice_priv])

      encoded = signed |> Signed.to_rlp() |> ExRLP.encode()

      assert {:ok, %Signed{} = decoded} = Transaction.decode(encoded, :signed)
      assert decoded == signed
    end

    test "returns `malformed_rlp` when not given rlp binary" do
      assert {:error, :malformed_rlp} = Transaction.decode(123, :signed)
    end

    test "returns `malformed_witnesses` when the given first item is not a list" do
      encoded = [<<1337>>, <<0>>] |> ExRLP.encode()
      assert {:error, :malformed_witnesses} = Transaction.decode(encoded, :signed)
    end

    test "returns `malformed_transaction` when not given a valid raw transaction" do
      encoded = <<0>> |> ExRLP.encode()
      assert {:error, :malformed_transaction} = Transaction.decode(encoded, :signed)
    end
  end

  describe "to_map/1" do
    test "returns the structure of the raw transaction" do
      tx = PaymentV1.new([], [])
      rlp = Protocol.to_rlp(tx)

      assert {:ok, mapped} = Transaction.to_map(rlp)
      assert mapped == tx
    end

    test "returns malformed_transaction error when not given a list" do
      assert Transaction.to_map(123) == {:error, :malformed_transaction}
    end

    test "returns `unrecognized_transaction_type` when the given type is not supported" do
      rlp = [<<1337>>, <<0>>]
      assert {:error, :unrecognized_transaction_type} = Transaction.to_map(rlp)
    end
  end

  describe "sign/2" do
    test "returns {:ok, signed} when given valid keys" do
      %{priv_encoded: key_1} = @alice
      %{priv_encoded: key_2} = @bob

      tx =
        PaymentV1Builder.new()
        |> PaymentV1Builder.add_input(blknum: 1, txindex: 0, oindex: 0, position: 1_000_000_000)
        |> PaymentV1Builder.add_input(blknum: 2, txindex: 0, oindex: 0, position: 2_000_000_000)
        |> PaymentV1Builder.add_input(blknum: 3, txindex: 0, oindex: 0, position: 3_000_000_000)

      assert {:ok, %Signed{} = signed} = Transaction.sign(tx, keys: [key_1, key_1, key_2])
      assert signed.raw_tx == tx
      assert [sig_1, sig_1, sig_2] = signed.sigs
    end
  end

  describe "get_inputs/1" do
    setup do
      i_1 = %Output{output_id: %{blknum: 1, txindex: 0, oindex: 0, position: 1_000_000_000}}
      i_2 = %Output{output_id: %{blknum: 2, txindex: 0, oindex: 0, position: 2_000_000_000}}

      tx = PaymentV1Builder.new(inputs: [i_1, i_2])

      {:ok, %{i_1: i_1, i_2: i_2, tx: tx}}
    end

    test "returns inputs of the underlying raw transaction for a raw transaction", %{tx: tx, i_1: i_1, i_2: i_2} do
      assert Transaction.get_inputs(tx) == [i_1, i_2]
    end

    test "returns inputs of the underlying raw transaction for a signed transaction", %{tx: tx, i_1: i_1, i_2: i_2} do
      %Signed{} = signed = PaymentV1Builder.sign!(tx, keys: [])

      assert Transaction.get_inputs(signed) == [i_1, i_2]
    end

    test "returns inputs of the underlying raw transaction for a recovered transaction", %{tx: tx, i_1: i_1, i_2: i_2} do
      %Signed{} = signed = PaymentV1Builder.sign!(tx, keys: [])

      {:ok, %Recovered{} = recovered} = Signed.encode(signed) |> Transaction.decode(:recovered)

      assert Transaction.get_inputs(recovered) == [i_1, i_2]
    end
  end

  describe "get_outputs/1" do
    setup do
      o_1 = PaymentV1.new_output(<<1::160>>, <<0::160>>, 1)
      o_2 = PaymentV1.new_output(<<1::160>>, <<0::160>>, 2)

      tx = PaymentV1Builder.new(outputs: [o_1, o_2])

      {:ok, %{o_1: o_1, o_2: o_2, tx: tx}}
    end

    test "returns outputs of the underlying raw transaction for a raw transaction", %{tx: tx, o_1: o_1, o_2: o_2} do
      assert Transaction.get_outputs(tx) == [o_1, o_2]
    end

    test "returns outputs of the underlying raw transaction for a signed transaction", %{tx: tx, o_1: o_1, o_2: o_2} do
      %Signed{} = signed = PaymentV1Builder.sign!(tx, keys: [])

      assert Transaction.get_outputs(signed) == [o_1, o_2]
    end

    test "returns outputs of the underlying raw transaction for a recovered transaction", %{tx: tx, o_1: o_1, o_2: o_2} do
      %Signed{} = signed = PaymentV1Builder.sign!(tx, keys: [])

      {:ok, %Recovered{} = recovered} = Signed.encode(signed) |> Transaction.decode(:recovered)

      assert Transaction.get_outputs(recovered) == [o_1, o_2]
    end
  end

  describe "get_tx_type/1" do
    setup do
      {:ok, %{tx: PaymentV1Builder.new()}}
    end

    test "returns the tx_type of the underlying raw transaction for a raw transaction", %{tx: tx} do
      assert Transaction.get_tx_type(tx) == 1
    end

    test "returns the tx_type of the underlying raw transaction for a signed transaction", %{tx: tx} do
      %Signed{} = signed = PaymentV1Builder.sign!(tx, keys: [])

      assert Transaction.get_tx_type(signed) == 1
    end

    test "returns the tx_type of the underlying raw transaction for a recovered transaction", %{tx: tx} do
      %Signed{} = signed = PaymentV1Builder.sign!(tx, keys: [])

      {:ok, %Recovered{} = recovered} = Signed.encode(signed) |> Transaction.decode(:recovered)

      assert Transaction.get_tx_type(recovered) == 1
    end
  end

  describe "encode/1" do
    setup do
      {:ok, %{tx: PaymentV1Builder.new()}}
    end

    test "returns the encoded raw transaction for a raw transaction", %{tx: tx} do
      encoded = Transaction.encode(tx)

      assert encoded == tx |> Protocol.to_rlp() |> ExRLP.encode()
    end

    test "returns the encoded signed transaction for a signed transaction", %{tx: tx} do
      %Signed{} = signed = PaymentV1Builder.sign!(tx, keys: [])

      encoded = Transaction.encode(signed)

      assert encoded == signed |> Signed.to_rlp() |> ExRLP.encode()
    end

    test "returns the encoded signed transaction for a recovered transaction", %{tx: tx} do
      %Signed{} = signed = PaymentV1Builder.sign!(tx, keys: [])

      {:ok, %Recovered{} = recovered} = Signed.encode(signed) |> Transaction.decode(:recovered)

      encoded = Transaction.encode(recovered)

      assert encoded == recovered.signed_tx |> Signed.to_rlp() |> ExRLP.encode()
    end
  end

  describe "hash/1" do
    setup do
      {:ok, %{tx: PaymentV1Builder.new()}}
    end

    test "returns the keccak hash of the encoded raw transaction for a raw transaction", %{tx: tx} do
      assert Transaction.hash(tx) == tx |> Transaction.encode() |> Crypto.keccak_hash()
    end

    test "returns the keccak hash of the encoded raw transaction for an encoded raw transaction", %{tx: tx} do
      encoded = Transaction.encode(tx)

      assert Transaction.hash(encoded) == Crypto.keccak_hash(encoded)
    end

    test "returns the keccak hash of the encoded underlying raw transaction for a signed transaction", %{tx: tx} do
      %Signed{} = signed = PaymentV1Builder.sign!(tx, keys: [])

      encoded = Transaction.encode(tx)

      assert Transaction.hash(signed) == Crypto.keccak_hash(encoded)
    end

    test "returns the tx_hash for a recovered transaction", %{tx: tx} do
      %Signed{} = signed = PaymentV1Builder.sign!(tx, keys: [])

      {:ok, %Recovered{} = recovered} = Signed.encode(signed) |> Transaction.decode(:recovered)

      assert Transaction.hash(recovered) == recovered.tx_hash
    end
  end
end
