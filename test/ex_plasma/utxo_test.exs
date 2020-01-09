defmodule ExPlasma.UtxoTest do
  use ExUnit.Case, async: true
  doctest ExPlasma.Utxo

  alias ExPlasma.Utxo

  describe "new/1" do
    test "does not allow amount to be zero" do
      assert {:error, {:amount, :cannot_be_zero}} == Utxo.new(%{amount: 0})
    end

    test "does not allow output guard / owner to be zero" do
      assert {:error, {:output_guard, :cannot_be_zero}} == Utxo.new(%{output_guard: <<0::160>>})
    end
  end

  describe "to_rlp/1" do
    test "encodes a zero position input utxo" do
      utxo = %Utxo{blknum: 0, oindex: 0, txindex: 0}
      rlp = Utxo.to_rlp(utxo)

      assert rlp ==
               <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                 0, 0, 0, 0, 0>>
    end
  end

  describe "encode/1" do
    test "encodes the output utxo into an eip712 encoded object" do
      encoded = ExPlasma.TypedData.encode(%Utxo{amount: 10})

      assert encoded ==
               [
                 "Output(uint256 outputType,bytes20 outputGuard,address currency,uint256 amount)",
                 <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                   0, 0, 0, 0, 0, 1>>,
                 <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                   0, 0, 0, 0, 0, 0>>,
                 <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                   0, 0, 0, 0, 0, 0>>,
                 <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                   0, 0, 0, 0, 0, 10>>
               ]
    end

    test "encodes the input utxo into an eip712 encoded object" do
      encoded = ExPlasma.TypedData.encode(%Utxo{blknum: 1000})

      assert encoded ==
               [
                 "Input(uint256 blknum,uint256 txindex,uint256 oindex)",
                 <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                   0, 0, 0, 0, 3, 232>>,
                 <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                   0, 0, 0, 0, 0, 0>>,
                 <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                   0, 0, 0, 0, 0, 0>>
               ]
    end
  end

  describe "hash/1" do
    test "encodes the input utxo into an eip712 encoded hash" do
      hashed = ExPlasma.TypedData.hash(%Utxo{})

      assert hashed ==
               <<26, 89, 51, 235, 11, 50, 35, 176, 80, 15, 187, 231, 3, 156, 171, 155, 173, 192,
                 6, 173, 218, 108, 243, 211, 55, 117, 20, 18, 253, 122, 75, 97>>
    end

    test "encodes the output utxo into an eip712 encoded hash" do
      hashed = ExPlasma.TypedData.hash(%Utxo{amount: 10})

      assert hashed ==
               <<215, 8, 60, 19, 55, 10, 155, 112, 243, 199, 49, 150, 131, 140, 14, 12, 157, 118,
                 195, 214, 198, 94, 223, 77, 159, 186, 45, 211, 125, 37, 234, 32>>
    end
  end
end
