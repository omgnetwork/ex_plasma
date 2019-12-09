defmodule Conformance.OMGTest do
  @moduledoc """
  This test suite checks to see if our encoding/hashing of transactions
  matches that of what `elixir-omg` does. This helps break down the individual steps
  for the final `signature` hash.
  """

  use ExUnit.Case, async: false

  alias ExPlasma.Encoding
  alias ExPlasma.Transactions.Payment
  alias ExPlasma.TypedData
  alias ExPlasma.Utxo

  @moduletag :conformance
  @moduletag :omg

  # RLP list from omg 
  # [
  # <<1>>,
  # [<<59, 154, 202, 0>>],
  # [],
  # <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  # 0>>
  # ]

  @omg_typed_data_single_input_payment_list [
    <<38, 48, 63, 231, 128, 240, 155, 213, 153, 100, 165, 127, 56, 40, 103, 117, 183, 196, 95,
      210, 82, 81, 149, 89, 139, 185, 166, 164, 142, 170, 171, 147>>,
    <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      1>>,
    [
      <<115, 119, 175, 205, 36, 253, 198, 133, 253, 140, 110, 162, 181, 209, 90, 116, 242, 200,
        152, 195, 213, 188, 206, 52, 153, 244, 72, 164, 214, 141, 178, 144>>,
      <<26, 89, 51, 235, 11, 50, 35, 176, 80, 15, 187, 231, 3, 156, 171, 155, 173, 192, 6, 173,
        218, 108, 243, 211, 55, 117, 20, 18, 253, 122, 75, 97>>,
      <<26, 89, 51, 235, 11, 50, 35, 176, 80, 15, 187, 231, 3, 156, 171, 155, 173, 192, 6, 173,
        218, 108, 243, 211, 55, 117, 20, 18, 253, 122, 75, 97>>,
      <<26, 89, 51, 235, 11, 50, 35, 176, 80, 15, 187, 231, 3, 156, 171, 155, 173, 192, 6, 173,
        218, 108, 243, 211, 55, 117, 20, 18, 253, 122, 75, 97>>
    ],
    [
      <<122, 211, 41, 71, 84, 226, 207, 196, 138, 148, 106, 183, 248, 236, 91, 125, 197, 15, 200,
        236, 188, 2, 54, 160, 32, 229, 201, 192, 219, 96, 169, 140>>,
      <<122, 211, 41, 71, 84, 226, 207, 196, 138, 148, 106, 183, 248, 236, 91, 125, 197, 15, 200,
        236, 188, 2, 54, 160, 32, 229, 201, 192, 219, 96, 169, 140>>,
      <<122, 211, 41, 71, 84, 226, 207, 196, 138, 148, 106, 183, 248, 236, 91, 125, 197, 15, 200,
        236, 188, 2, 54, 160, 32, 229, 201, 192, 219, 96, 169, 140>>,
      <<122, 211, 41, 71, 84, 226, 207, 196, 138, 148, 106, 183, 248, 236, 91, 125, 197, 15, 200,
        236, 188, 2, 54, 160, 32, 229, 201, 192, 219, 96, 169, 140>>
    ],
    <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0>>
  ]

  @single_input_payment_struct %Payment{
    inputs: [
      %Utxo{
        amount: 0,
        blknum: 1,
        currency: "0x0000000000000000000000000000000000000000",
        oindex: 0,
        output_type: 1,
        owner: "0x0000000000000000000000000000000000000000",
        txindex: 0
      }
    ],
    metadata:
      <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0>>,
    outputs: [],
    sigs: []
  }

  describe "single input payment transaction" do
    test "should have same signature encoding" do
      [_prefix, _domain, signature, _transaction_type, _inputs, _outputs, _metadata] =
        @single_input_payment_struct |> TypedData.encode()

      [omg_signature, _transaction_type, _inputs, _outputs, _metadata] =
        @omg_typed_data_single_input_payment_list

      assert omg_signature == signature |> Encoding.keccak_hash()
    end
  end

  test "should have same signature encoding" do
    [
      _prefix,
      _domain,
      signature,
      transaction_type,
      inputs,
      _outputs,
      metadata
    ] = @single_input_payment_struct |> TypedData.encode()

    [
      omg_signature,
      omg_transaction_type,
      omg_inputs,
      _omg_outputs,
      omg_metadata
    ] = @omg_typed_data_single_input_payment_list

    assert omg_signature == signature |> Encoding.keccak_hash()
    assert transaction_type == omg_transaction_type
    assert metadata == omg_metadata

    input = inputs |> hd()
    # output = outputs |> hd()

    assert Conformance.OMGTest.hash(input) == omg_inputs |> hd()
  end

  def hash([signature | encoded_list]) do
    ([Encoding.keccak_hash(signature)] ++ encoded_list)
    |> Enum.join()
    |> Encoding.keccak_hash()
  end
end
