defmodule ExPlasma.TypedData.TransactionTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias ExPlasma.Crypto
  alias ExPlasma.Transaction

  describe "encode/1" do
    test "builds a eip712 transaction object" do
      encoded = ExPlasma.TypedData.encode(%Transaction{tx_type: 1})

      assert encoded == [
               <<25, 1>>,
               [
                 "EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)",
                 "OMG Network",
                 "2",
                 "0xd17e1233a03affb9092d5109179b43d6a8828607",
                 "0xfad5c7f626d80f9256ef01929f3beb96e058b8b4b0e3fe52d84f054c0e2a7a83"
               ],
               Crypto.keccak_hash(
                 "Transaction(uint256 txType,Input[] inputs,Output[] outputs,uint256 txData,bytes32 metadata)Input(uint256 blknum,uint256 txindex,uint256 oindex)Output(uint256 outputType,bytes20 outputGuard,address currency,uint256 amount)"
               ),
               <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1>>,
               <<197, 210, 70, 1, 134, 247, 35, 60, 146, 126, 125, 178, 220, 199, 3, 192, 229, 0, 182, 83, 202, 130, 39,
                 59, 123, 250, 216, 4, 93, 133, 164, 112>>,
               <<197, 210, 70, 1, 134, 247, 35, 60, 146, 126, 125, 178, 220, 199, 3, 192, 229, 0, 182, 83, 202, 130, 39,
                 59, 123, 250, 216, 4, 93, 133, 164, 112>>,
               <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
               <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>
             ]
    end
  end

  describe "hash/1" do
    test "hashes a eip 712 encoded object" do
      encoded_hash = ExPlasma.TypedData.hash(%Transaction{tx_type: 1})

      assert encoded_hash == "\x8E\xCB\xDA\xF2\x1Fԕ@G\x8B^i\xEESr\x1AΝ\x04\x98\x1D\x11\xF1J\x8F\xA0$\xFFc,\xD3\v"
    end
  end
end
