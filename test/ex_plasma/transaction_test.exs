defmodule ExPlasma.TransactionTest do
  @moduledoc false
  use ExUnit.Case, async: true
  doctest ExPlasma.Transaction

  alias ExPlasma.Transaction

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

    test "returns {:error, :corrupted_witness} when the signature is invalid" do
      txn = %Transaction{
        inputs: [],
        metadata: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
        outputs: [],
        sigs: [<<1>>],
        tx_data: <<0>>,
        tx_type: <<1>>
      }

      assert Transaction.recover_signatures(txn) == {:error, :corrupted_witness}
    end
  end

  defp assert_field(data, field, message) do
    assert {:error, {^field, ^message}} = Transaction.validate(data)
  end
end
