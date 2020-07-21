defmodule ExPlasma.TransactionTest do
  @moduledoc false
  use ExUnit.Case, async: true
  doctest ExPlasma.Transaction

  alias ExPlasma.Transaction

  @transaction %Transaction{
    inputs: [
      %ExPlasma.Output{
        output_data: nil,
        output_id: %{blknum: 0, oindex: 0, position: 0, txindex: 0},
        output_type: nil
      }
    ],
    metadata: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
    outputs: [
      %ExPlasma.Output{
        output_data: %{
          amount: 10,
          output_guard: <<21, 248, 47, 41, 27, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110>>,
          token: <<46, 38, 45, 41, 28, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110>>
        },
        output_id: nil,
        output_type: 1
      }
    ],
    sigs: [],
    tx_data: <<0>>,
    tx_type: 1
  }

  describe "encode/1" do
    test "encodes a transaction struct" do
      result = Transaction.encode(@transaction)

      expected_result =
        <<248, 104, 1, 225, 160, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
          0, 0, 0, 238, 237, 1, 235, 148, 21, 248, 47, 41, 27, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241,
          55, 0, 110, 148, 46, 38, 45, 41, 28, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110, 10,
          128, 148, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>

      assert expected_result == result
    end

    test "encodes raw list" do
      data = [<<1>>, "7", "test"]

      result = Transaction.encode(data)

      expected_result = <<199, 1, 55, 132, 116, 101, 115, 116>>

      assert expected_result == result
      assert ExRLP.decode(expected_result) == data
    end
  end

  describe "decode/1" do
    test "raises an exception is transaction type is unknown" do
      assert_raise ArgumentError, ~r/^transaction type 3 does not exist/, fn ->
        rlp =
          <<248, 74, 192, 3, 193, 128, 239, 174, 237, 3, 235, 148, 29, 246, 47, 41, 27, 46, 150, 159, 176, 132, 157,
            153, 217, 206, 65, 226, 241, 55, 0, 110, 148, 46, 38, 45, 41, 28, 46, 150, 159, 176, 132, 157, 153, 217,
            206, 65, 226, 241, 55, 0, 110, 1, 128, 148, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>

        Transaction.decode(rlp)
      end
    end

    test "decodes a transaction" do
      rlp =
        <<248, 74, 192, 1, 193, 128, 239, 174, 237, 1, 235, 148, 11, 246, 22, 41, 33, 46, 44, 159, 55, 132, 157, 153,
          217, 206, 65, 226, 241, 55, 0, 110, 148, 46, 38, 45, 41, 28, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65,
          226, 241, 55, 0, 110, 1, 128, 148, 0, 11, 0, 22, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>

      result = Transaction.decode(rlp)

      expected_result = %ExPlasma.Transaction{
        inputs: [
          %ExPlasma.Output{
            output_data: nil,
            output_id: %{blknum: 0, oindex: 0, position: 0, txindex: 0},
            output_type: nil
          }
        ],
        metadata: <<0, 11, 0, 22, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
        outputs: [
          %ExPlasma.Output{
            output_data: %{
              amount: 1,
              output_guard: <<11, 246, 22, 41, 33, 46, 44, 159, 55, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110>>,
              token: <<46, 38, 45, 41, 28, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110>>
            },
            output_id: nil,
            output_type: 1
          }
        ],
        sigs: [],
        tx_data: 0,
        tx_type: 1
      }

      assert result == expected_result
    end
  end

  describe "to_rlp/1" do
    test "raises an exception if type is uknown" do
      assert_raise ArgumentError, ~r/^transaction type 10 does not exist/, fn ->
        transaction = %Transaction{
          inputs: [
            %ExPlasma.Output{
              output_data: nil,
              output_id: %{blknum: 0, oindex: 0, position: 0, txindex: 0},
              output_type: nil
            }
          ],
          metadata: <<0, 11, 0, 22, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
          outputs: [
            %ExPlasma.Output{
              output_data: %{
                amount: 1,
                output_guard:
                  <<11, 246, 22, 41, 33, 46, 44, 159, 55, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110>>,
                token: <<46, 38, 45, 41, 28, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110>>
              },
              output_id: nil,
              output_type: 1
            }
          ],
          sigs: [],
          tx_data: 0,
          tx_type: 10
        }

        Transaction.to_rlp(transaction)
      end
    end

    test "converts transaction to rlp representation" do
      result = Transaction.to_rlp(@transaction)

      expected_result = [
        <<1>>,
        [
          <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>
        ],
        [
          [
            <<1>>,
            [
              <<21, 248, 47, 41, 27, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110>>,
              <<46, 38, 45, 41, 28, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110>>,
              "\n"
            ]
          ]
        ],
        0,
        <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>
      ]

      assert result == expected_result
    end
  end

  describe "validate/1" do
    test "that the inputs in a transaction have valid positions" do
      bad_position =
        1_000_000_000_000_000_000_000
        |> :binary.encode_unsigned(:big)
        |> ExPlasma.Output.decode_id()

      txn = %Transaction{
        inputs: [bad_position],
        metadata: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
        outputs: [
          %{
            output_data: %{
              amount: 1,
              output_guard:
                <<29, 246, 47, 41, 27, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110>>,
              token: <<46, 38, 45, 41, 28, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110>>
            },
            output_id: nil,
            output_type: 1
          }
        ],
        sigs: [],
        tx_data: <<0>>,
        tx_type: <<1>>
      }

      assert_field(txn, :blknum, :exceeds_maximum_value)
    end

    test "that the outputs in a transaction are valid outputs" do
      # zero amount output
      bad_output = ExPlasma.Output.decode([<<1>>, [<<1::160>>, <<0::160>>, <<0>>]])

      txn = %Transaction{
        inputs: [],
        metadata: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
        outputs: [bad_output],
        sigs: [],
        tx_data: <<0>>,
        tx_type: <<1>>
      }

      assert_field(txn, :amount, :cannot_be_zero)
    end

    test "raises an error if given an invalid transaction type" do
      txn = %Transaction{
        inputs: [],
        metadata: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
        outputs: [],
        sigs: [],
        tx_data: <<0>>,
        tx_type: 100
      }

      assert_raise ArgumentError, "transaction type 100 does not exist.", fn ->
        Transaction.validate(txn)
      end
    end
  end

  describe "sign/2" do
    test "returns empty sigs if keys are empty" do
      transaction = Transaction.sign(@transaction, keys: [])

      assert transaction.sigs == []
    end

    test "signs inputs of the transaction" do
      key = "0x8da4ef21b864d2cc526dbdb2a120bd2874c36c9d0a1fb7f8c63d7f7a8b41de8f"
      address = <<99, 250, 201, 32, 20, 148, 240, 189, 23, 185, 137, 43, 159, 174, 77, 82, 254, 59, 211, 119>>

      input =
        10
        |> :binary.encode_unsigned(:big)
        |> ExPlasma.Output.decode_id()

      transaction = %Transaction{
        inputs: [input],
        metadata: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
        outputs: [],
        sigs: [],
        tx_data: <<0>>,
        tx_type: <<1>>
      }

      signed_transaction = Transaction.sign(transaction, keys: [key])
      assert Transaction.recover_signatures(signed_transaction) == {:ok, [address]}
    end
  end

  describe "hash/1" do
    test "calculates transaction hash for struct" do
      result = Transaction.hash(@transaction)

      expected_result =
        <<252, 0, 240, 59, 229, 14, 205, 53, 213, 3, 30, 176, 212, 154, 35, 38, 149, 140, 182, 182, 156, 80, 244, 192,
          187, 25, 148, 38, 215, 8, 96, 37>>

      assert result == expected_result
    end

    test "calculates hash for rlp encoded transaction" do
      result = @transaction |> Transaction.encode() |> Transaction.hash()

      expected_result =
        <<252, 0, 240, 59, 229, 14, 205, 53, 213, 3, 30, 176, 212, 154, 35, 38, 149, 140, 182, 182, 156, 80, 244, 192,
          187, 25, 148, 38, 215, 8, 96, 37>>

      assert result == expected_result
    end
  end

  describe "recover_signatures/1" do
    test "returns {:ok, addresses} when signatures are valid" do
      key_1 = "0x0C79EF4FEEA6232854ABFE4006161FC517F4071E5384DBDEF72718B4A4AF016E"
      key_2 = "0x33B41524C9E74DE1F440107E05EEE78754F92F237D23A2655E0370B99EB86568"
      addr_1 = ExPlasma.Encoding.to_binary("0xD2d7369Cdb7EE58cccccd9129f92B0c49Be7CCa3")
      addr_2 = ExPlasma.Encoding.to_binary("0x93E804B024573e18B6Ee6e36E2864548AcA72240")

      i_1 =
        1_000_000
        |> :binary.encode_unsigned(:big)
        |> ExPlasma.Output.decode_id()

      i_2 =
        1_000_001
        |> :binary.encode_unsigned(:big)
        |> ExPlasma.Output.decode_id()

      txn = %Transaction{
        inputs: [i_1, i_2],
        metadata: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
        outputs: [],
        sigs: [],
        tx_data: <<0>>,
        tx_type: <<1>>
      }

      signed_txn = Transaction.sign(txn, keys: [key_1, key_2])

      assert Transaction.recover_signatures(signed_txn) == {:ok, [addr_1, addr_2]}
    end

    test "returns {:error, :invalid_signature} when the signature is invalid" do
      txn = %Transaction{
        inputs: [],
        metadata: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
        outputs: [],
        sigs: [<<1>>],
        tx_data: <<0>>,
        tx_type: <<1>>
      }

      assert Transaction.recover_signatures(txn) == {:error, :invalid_signature}
    end
  end

  defp assert_field(data, field, message) do
    assert {:error, {^field, ^message}} = Transaction.validate(data)
  end
end
