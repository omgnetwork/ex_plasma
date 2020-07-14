defmodule ExPlasma.Transaction.Type.FeeTest do
  @moduledoc false
  use ExUnit.Case, async: true
  doctest ExPlasma.Transaction.Type.Fee, import: true

  alias ExPlasma.Output
  alias ExPlasma.Transaction.Protocol
  alias ExPlasma.Transaction.Type.Fee

  describe "new/2" do
    test "returns a new transaction with given fields" do
      fee_claimer = <<1::160>>
      token = <<0::160>>
      amount = 1337

      tx = Fee.new(1000, {fee_claimer, token, amount})

      assert tx == %Fee{
               tx_type: 3,
               outputs: [
                 %Output{
                   output_type: 2,
                   output_data: %{
                     amount: amount,
                     output_guard: fee_claimer,
                     token: token
                   }
                 }
               ],
               nonce:
                 <<61, 119, 206, 68, 25, 203, 29, 23, 147, 224, 136, 32, 198, 128, 177, 74, 227, 250, 194, 173, 146,
                   182, 251, 152, 123, 172, 26, 83, 175, 194, 213, 238>>
             }
    end
  end

  describe "new_output/3" do
    test "returns a new fee output with the given params" do
      output = Fee.new_output(<<0::160>>, <<0::160>>, 1337)

      assert output == %Output{
               output_data: %{amount: 1337, output_guard: <<0::160>>, token: <<0::160>>},
               output_id: nil,
               output_type: 2
             }
    end
  end

  describe "to_rlp/1" do
    test "returns the rlp item list of the given fee transaction" do
      tx = Fee.new(1000, {<<1::160>>, <<0::160>>, 1})

      rlp = Protocol.to_rlp(tx)

      assert rlp == [
               # tx type
               <<3>>,
               [
                 [
                   # Output type
                   <<2>>,
                   [
                     # Output guard
                     <<1::160>>,
                     # Output token
                     <<0::160>>,
                     # Output amount
                     <<1>>
                   ]
                 ]
               ],
               # nonce
               <<61, 119, 206, 68, 25, 203, 29, 23, 147, 224, 136, 32, 198, 128, 177, 74, 227, 250, 194, 173, 146, 182,
                 251, 152, 123, 172, 26, 83, 175, 194, 213, 238>>
             ]
    end
  end

  describe "to_map/2" do
    test "returns a fee struct from an rlp list when valid" do
      rlp = [
        # tx type
        <<3>>,
        [
          [
            # Output type
            <<2>>,
            [
              # Output guard
              <<1::160>>,
              # Output token
              <<0::160>>,
              # Output amount
              <<1>>
            ]
          ]
        ],
        # nonce
        <<61, 119, 206, 68, 25, 203, 29, 23, 147, 224, 136, 32, 198, 128, 177, 74, 227, 250, 194, 173, 146, 182, 251,
          152, 123, 172, 26, 83, 175, 194, 213, 238>>
      ]

      assert {:ok, tx} = Protocol.to_map(%Fee{}, rlp)

      assert tx == %Fee{
               nonce:
                 <<61, 119, 206, 68, 25, 203, 29, 23, 147, 224, 136, 32, 198, 128, 177, 74, 227, 250, 194, 173, 146,
                   182, 251, 152, 123, 172, 26, 83, 175, 194, 213, 238>>,
               outputs: [
                 %Output{
                   output_data: %{amount: 1, output_guard: <<1::160>>, token: <<0::160>>},
                   output_id: nil,
                   output_type: 2
                 }
               ],
               tx_type: 3
             }
    end

    test "returns a `malformed_transaction` error when the rlp is invalid" do
      assert Protocol.to_map(%Fee{}, [<<3>>, <<1>>]) == {:error, :malformed_transaction}
    end
  end

  describe "get_inputs/1" do
    test "returns an empty list" do
      tx = Fee.new(1000, {<<1::160>>, <<0::160>>, 1})

      assert Protocol.get_inputs(tx) == []
    end
  end

  describe "get_outputs/1" do
    test "returns the transaction outputs with 1 element inside" do
      tx = Fee.new(1000, {<<1::160>>, <<0::160>>, 1})

      assert Protocol.get_outputs(tx) == [
               %Output{
                 output_data: %{amount: 1, output_guard: <<1::160>>, token: <<0::160>>},
                 output_id: nil,
                 output_type: 2
               }
             ]
    end
  end

  describe "get_tx_type" do
    test "returns a fee type" do
      tx = Fee.new(1000, {<<1::160>>, <<0::160>>, 1})

      assert Protocol.get_tx_type(tx) == 3
    end
  end

  describe "validate/1" do
    test "returns :ok when valid" do
      tx = Fee.new(1000, {<<1::160>>, <<0::160>>, 1})

      assert Protocol.validate(tx) == :ok
    end

    test "returns an error when generic output is not valid" do
      tx = Fee.new(1000, {<<1::160>>, <<0::160>>, 0})

      assert_field(tx, :amount, :cannot_be_zero)
    end

    test "returns an error when outputs count is greater than 1" do
      outputs =
        Enum.reduce(1..6, [], fn i, acc ->
          [Fee.new_output(<<1::160>>, <<0::160>>, i) | acc]
        end)

      tx = %Fee{
        tx_type: 3,
        outputs: outputs,
        nonce: <<0>>
      }

      assert_field(tx, :outputs, :wrong_number_of_fee_outputs)
    end

    test "returns an error when outputs count is 0" do
      tx = %Fee{
        tx_type: 3,
        outputs: [],
        nonce: <<0>>
      }

      assert_field(tx, :outputs, :wrong_number_of_fee_outputs)
    end

    test "returns an error when output type is not a fee" do
      output = %Output{
        output_data: %{amount: 2, output_guard: <<2::160>>, token: <<0::160>>},
        output_id: nil,
        output_type: 1
      }

      tx = %Fee{
        tx_type: 3,
        outputs: [output],
        nonce: <<0>>
      }

      assert_field(tx, :outputs, :invalid_output_type_for_transaction)
    end

    test "returns an error when the nonce is not in the right format" do
      output = %Output{
        output_data: %{amount: 2, output_guard: <<2::160>>, token: <<0::160>>},
        output_id: nil,
        output_type: 2
      }

      tx = %Fee{
        tx_type: 3,
        outputs: [output],
        nonce: <<0>>
      }

      assert_field(tx, :nonce, :malformed_nonce)
    end
  end

  defp assert_field(data, field, message) do
    assert {:error, {^field, ^message}} = Protocol.validate(data)
  end
end
