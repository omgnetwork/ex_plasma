defmodule ExPlasma.UtxoTest do
  use ExUnit.Case, async: true
  doctest ExPlasma.Utxo

  alias ExPlasma.Utxo

  describe "new/1" do
    test "validates all output utxo fields are present" do
      assert Utxo.new(%Utxo{amount: nil, currency: <<0::160>>, owner: <<1::160>>}) ==
               {:error, {:amount, :cannot_be_nil}}

      assert Utxo.new(%Utxo{amount: 1, currency: nil, owner: <<1::160>>}) ==
               {:error, {:currency, :cannot_be_nil}}

      assert Utxo.new(%Utxo{amount: 1, currency: <<0::160>>, owner: nil}) ==
               {:error, {:owner, :cannot_be_nil}}
    end

    test "validates all input utxo fields are present" do
      assert Utxo.new(%Utxo{blknum: nil, txindex: 0, oindex: 0}) ==
               {:error, {:blknum, :cannot_be_nil}}

      assert Utxo.new(%Utxo{blknum: 0, txindex: nil, oindex: 0}) ==
               {:error, {:txindex, :cannot_be_nil}}

      assert Utxo.new(%Utxo{blknum: 0, txindex: 0, oindex: nil}) ==
               {:error, {:oindex, :cannot_be_nil}}
    end

    test "does not allow amount to be zero" do
      assert Utxo.new(%Utxo{amount: 0, currency: <<0::160>>, owner: <<1::160>>}) ==
               {:error, {:amount, :cannot_be_zero}}

      rlp = [
        ExPlasma.payment_v1(),
        [
          <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1>>,
          <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
          <<0>>
        ]
      ]

      assert Utxo.new(rlp) == {:error, {:amount, :cannot_be_zero}}
    end

    test "does not allow output guard / owner to be zero" do
      assert Utxo.new(%Utxo{amount: 0, currency: <<0::160>>, owner: <<0::160>>}) ==
               {:error, {:owner, :cannot_be_zero}}

      rlp = [
        ExPlasma.payment_v1(),
        [
          <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
          <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
          ExPlasma.payment_v1()
        ]
      ]

      assert Utxo.new(rlp) == {:error, {:owner, :cannot_be_zero}}
    end

    test "does not allow blknum to exceed maximum" do
      assert Utxo.new(1_000_000_000_000_000_000_000) == {:error, {:blknum, :exceeds_maximum}}

      assert Utxo.new(%Utxo{blknum: 1_000_000_000_000, txindex: 0, oindex: 0}) ==
               {:error, {:blknum, :exceeds_maximum}}
    end

    test "does not allow txindex to exceed maximum" do
      assert Utxo.new(1_655_360_000) == {:error, {:txindex, :exceeds_maximum}}

      assert Utxo.new(%Utxo{blknum: 1, txindex: 65_536, oindex: 0}) ==
               {:error, {:txindex, :exceeds_maximum}}
    end

    test "decodes amount properly" do
      Enum.map(1..65_000, fn amount ->
        rlp = [1, [<<1::160>>, <<0::160>>, :binary.encode_unsigned(amount, :big)]]

        assert {:ok, %Utxo{amount: amount}} = Utxo.new(rlp)
      end)
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
      utxo = %Utxo{amount: 10, currency: <<0::160>>, owner: <<0::160>>}
      encoded = ExPlasma.TypedData.encode(utxo)

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
      utxo = %Utxo{blknum: 1000, txindex: 0, oindex: 0}
      encoded = ExPlasma.TypedData.encode(utxo)

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
      utxo = %Utxo{blknum: 0, txindex: 0, oindex: 0}
      hashed = ExPlasma.TypedData.hash(utxo)

      assert hashed ==
               <<26, 89, 51, 235, 11, 50, 35, 176, 80, 15, 187, 231, 3, 156, 171, 155, 173, 192,
                 6, 173, 218, 108, 243, 211, 55, 117, 20, 18, 253, 122, 75, 97>>
    end

    test "encodes the output utxo into an eip712 encoded hash" do
      utxo = %Utxo{amount: 10, currency: <<0::160>>, owner: <<0::160>>}
      hashed = ExPlasma.TypedData.hash(utxo)

      assert hashed ==
               <<215, 8, 60, 19, 55, 10, 155, 112, 243, 199, 49, 150, 131, 140, 14, 12, 157, 118,
                 195, 214, 198, 94, 223, 77, 159, 186, 45, 211, 125, 37, 234, 32>>
    end
  end
end
