defmodule ExPlasma.TransactionTest do
  @moduledoc false
  use ExUnit.Case, async: true

  # doctest ExPlasma.Transaction

  alias ExPlasma.Crypto
  alias ExPlasma.Output
  alias ExPlasma.Builder
  alias ExPlasma.Support.TestEntity
  alias ExPlasma.Transaction
  alias ExPlasma.Transaction.Protocol
  alias ExPlasma.Transaction.Recovered
  alias ExPlasma.Transaction.Signed
  alias ExPlasma.Transaction.Type.PaymentV1

  @alice TestEntity.alice()
  @bob TestEntity.bob()
  @eth <<0::160>>

  describe "decode/1" do
    test "successfuly decodes when given valid encoded signed transaction" do
      %{priv_encoded: alice_priv} = @alice
      %{addr: bob_addr} = @bob

      signed =
        Builder.new()
        |> Builder.add_input(blknum: 1, txindex: 0, oindex: 0, position: 1_000_000_000)
        |> Builder.add_input(blknum: 2, txindex: 0, oindex: 0, position: 2_000_000_000)
        |> Builder.add_output(output_guard: bob_addr, token: @eth, amount: 12)
        |> Builder.sign!([alice_priv, alice_priv])

      encoded = signed |> Transaction.to_rlp() |> ExRLP.encode()

      assert {:ok, %Transaction{} = decoded} = Transaction.decode(encoded)
      assert decoded == signed
    end

    test "returns `malformed_rlp` when not given rlp binary" do
      assert Transaction.decode(123) == {:error, :malformed_rlp}
    end

    test "returns `malformed_witnesses` when the given first item is not a list" do
      encoded = ExRLP.encode([<<1337>>, <<0>>])
      assert Transaction.decode(encoded) == {:error, :malformed_witnesses}
    end

    test "returns `malformed_transaction` when not given a valid raw transaction" do
      encoded = ExRLP.encode(<<0>>)
      assert Transaction.decode(encoded) == {:error, :malformed_transaction}
    end
  end

  describe "to_map/1" do
    test "maps an rlp list of items into a Transaction structure" do
      tx = %Transaction{tx_type: 1}
      rlp = Transaction.to_rlp(tx)

      assert {:ok, mapped} = Transaction.to_map(rlp)
      assert mapped == tx
    end

    test "returns malformed_transaction error when not given a list" do
      assert Transaction.to_map(123) == {:error, :malformed_transaction}
    end

    test "returns `unrecognized_transaction_type` when the given type is not supported" do
      assert Transaction.to_map([<<1337>>, <<0>>]) == {:error, :unrecognized_transaction_type}
    end
  end

  describe "sign/2" do
    test "returns {:ok, signed} when given valid keys" do
      %{priv_encoded: key_1} = @alice
      %{priv_encoded: key_2} = @bob

      tx =
        Builder.new()
        |> Builder.add_input(blknum: 1, txindex: 0, oindex: 0, position: 1_000_000_000)
        |> Builder.add_input(blknum: 2, txindex: 0, oindex: 0, position: 2_000_000_000)
        |> Builder.add_input(blknum: 3, txindex: 0, oindex: 0, position: 3_000_000_000)

      assert {:ok, %Transaction{} = signed} = Transaction.sign(tx, [key_1, key_1, key_2])
      assert [sig_1, sig_1, sig_2] = signed.sigs
    end

    test "returns {:error, :not_signable} when given an invalid struct" do
      assert {:error, :not_signable} = Transaction.sign(%{}, [key_1, key_1, key_2])
    end
  end

  describe "encode/1" do
    setup do
      {:ok, %{tx: Builder.new(1)}}
    end

    test "returns the encoded signed transaction for a signed transaction", %{tx: tx} do
      %Transaction{} = signed = Builder.sign!(tx, [])

      encoded = Transaction.encode(signed)

      assert encoded == signed |> Transaction.to_rlp() |> ExRLP.encode()
    end
  end

  describe "hash/1" do
    setup do
      {:ok, %{tx: Builder.new()}}
    end

    test "calculates transaction hash for struct", %{tx: tx} do
      result = Transaction.hash(tx)

      expected_result =
        <<252, 0, 240, 59, 229, 14, 205, 53, 213, 3, 30, 176, 212, 154, 35, 38, 149, 140, 182, 182, 156, 80, 244, 192,
          187, 25, 148, 38, 215, 8, 96, 37>>

      assert result == expected_result
    end

    test "calculates hash for rlp encoded transaction", %{tx: tx} do
      result = tx |> Transaction.encode() |> Transaction.hash()

      expected_result =
        <<252, 0, 240, 59, 229, 14, 205, 53, 213, 3, 30, 176, 212, 154, 35, 38, 149, 140, 182, 182, 156, 80, 244, 192,
          187, 25, 148, 38, 215, 8, 96, 37>>

      assert result == expected_result
    end
  end
end
