defmodule ExPlasma.TransactionTest do
  use ExUnit.Case, async: true
  doctest ExPlasma.Transaction

  alias ExPlasma.Transaction

  test "to_rlp/1 includes the sigs for a transaction" do
    transaction = %Transaction{
      sigs: ["0x6cbed15c793ce57650b9877cf6fa156fbef513c4e6134f022a85b1ffdd59b2a1"]
    }

    list = Transaction.to_rlp(transaction)

    assert list == [
             ["0x6cbed15c793ce57650b9877cf6fa156fbef513c4e6134f022a85b1ffdd59b2a1"],
             0,
             [],
             [],
             0,
             <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
               0, 0, 0, 0>>
           ]
  end

  test "encode/1 will encode a transaction with sigs" do
    transaction = %Transaction{
      sigs: ["0x6cbed15c793ce57650b9877cf6fa156fbef513c4e6134f022a85b1ffdd59b2a1"]
    }

    encoded = Transaction.encode(transaction)

    assert encoded ==
             <<248, 107, 248, 68, 184, 66, 48, 120, 54, 99, 98, 101, 100, 49, 53, 99, 55, 57, 51,
               99, 101, 53, 55, 54, 53, 48, 98, 57, 56, 55, 55, 99, 102, 54, 102, 97, 49, 53, 54,
               102, 98, 101, 102, 53, 49, 51, 99, 52, 101, 54, 49, 51, 52, 102, 48, 50, 50, 97,
               56, 53, 98, 49, 102, 102, 100, 100, 53, 57, 98, 50, 97, 49, 128, 192, 192, 128,
               160, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
               0, 0, 0, 0, 0, 0>>
  end

  describe "TypedData" do
    test "encode/1 encodes a transaction eip 712 object" do
      encoded = ExPlasma.TypedData.encode(%Transaction{})

      assert encoded == [
               <<25, 1>>,
               [
                 "EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)",
                 "OMG Network",
                 "1",
                 "0xd17e1233a03affb9092d5109179b43d6a8828607",
                 "0xfad5c7f626d80f9256ef01929f3beb96e058b8b4b0e3fe52d84f054c0e2a7a83"
               ],
               "Transaction(uint256 txType,Input input0,Input input1,Input input2,Input input3,Output output0,Output output1,Output output2,Output output3,uint256 txData,bytes32 metadata)Input(uint256 blknum,uint256 txindex,uint256 oindex)Output(uint256 outputType,bytes20 outputGuard,address currency,uint256 amount)",
               <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                 0, 0, 0, 0, 0>>,
               [],
               [],
               <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                 0, 0, 0, 0, 0>>,
               <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                 0, 0, 0, 0, 0>>
             ]
    end

    test "hash/1 encodes the transaction into an eip712 encoded hash" do
      encoded_hash = ExPlasma.TypedData.hash(%Transaction{})

      assert encoded_hash ==
               <<237, 222, 56, 55, 149, 76, 223, 131, 240, 226, 246, 122, 166, 114, 38, 102, 122,
                 183, 230, 80, 135, 114, 118, 119, 47, 205, 121, 140, 23, 172, 117, 213>>
    end
  end
end
