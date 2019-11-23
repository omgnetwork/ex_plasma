defmodule ExPlasma.Transaction.UtxoTest do
  use ExUnit.Case, async: true
  doctest ExPlasma.Transaction.Utxo

  alias ExPlasma.Transaction.Utxo

  describe "encode1/" do
    test "encodes the output utxo into an eip712 encoded object" do
      encoded = ExPlasma.TypedData.encode(%Utxo{})

      assert encoded ==
               [
                 "Output(uint256 outputType,bytes20 outputGuard,address currency,uint256 amount)",
                 <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                   0, 0, 0, 0, 1>>,
                 <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                   0, 0, 0, 0, 0>>,
                 <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                   0, 0, 0, 0, 0>>,
                 <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                   0, 0, 0, 0, 0>>
               ]
    end

    test "encodes the input utxo into an eip712 encoded object" do
      encoded = ExPlasma.TypedData.encode(%Utxo{blknum: 1000})

      assert encoded ==
               [
                 "Input(uint256 blknum,uint256 txindex,uint256 oindex)",
                 <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                   0, 0, 0, 3, 232>>,
                 <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                   0, 0, 0, 0, 0>>,
                 <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                   0, 0, 0, 0, 0>>,
               ]
    end
  end


  test "hash/1 encodes the utxo into an eip712 encoded hash" do
    hashed = ExPlasma.TypedData.hash(%Utxo{})

    assert hashed ==
             <<22, 128, 49, 205, 142, 208, 94, 252, 229, 149, 39, 106, 89, 4, 92, 171, 247, 163,
               61, 20, 164, 220, 173, 30, 161, 111, 221, 12, 152, 173, 117, 152>>
  end
end
