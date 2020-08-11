defmodule ExPlasma.Transaction.Type.FeeTest do
  @moduledoc false
  use ExUnit.Case, async: true
  doctest ExPlasma.Transaction.Type.Fee, import: true

  alias ExPlasma.Builder
  alias ExPlasma.Output
  alias ExPlasma.Transaction
  alias ExPlasma.Transaction.Type.Fee

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

  describe "build_nonce/1" do
    test "builds a valid nonce with the given params" do
      assert {:ok, nonce} = Fee.build_nonce(%{blknum: 1000, token: <<0::160>>})

      assert nonce ==
               <<61, 119, 206, 68, 25, 203, 29, 23, 147, 224, 136, 32, 198, 128, 177, 74, 227, 250, 194, 173, 146, 182,
                 251, 152, 123, 172, 26, 83, 175, 194, 213, 238>>
    end

    test "returns an error when not given correct params" do
      assert Fee.build_nonce(%{}) == {:error, :invalid_nonce_params}
    end
  end

  describe "to_rlp/1" do
    test "returns the rlp item list of the given fee transaction" do
      blknum = 1000
      token = <<0::160>>
      output = Fee.new_output(<<1::160>>, token, 1)

      tx =
        ExPlasma.fee()
        |> Builder.new(outputs: [output])
        |> Builder.with_nonce!(%{token: token, blknum: blknum})

      rlp = Fee.to_rlp(tx)

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

  describe "to_map/1" do
    test "returns a transaction struct from an rlp list when valid" do
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

      assert {:ok, tx} = Fee.to_map(rlp)

      assert tx == %Transaction{
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
      assert Fee.to_map([<<3>>, <<1>>]) == {:error, :malformed_transaction}
    end

    test "returns a `malformed_outputs` error when the outputs are not a list" do
      assert Fee.to_map([<<3>>, 123, <<1>>]) == {:error, :malformed_outputs}
    end

    test "returns a `malformed_outputs` error when the outputs are not a valid encoded output" do
      assert Fee.to_map([<<3>>, [123], <<1>>]) == {:error, :malformed_outputs}
    end
  end

  describe "validate/1" do
    test "returns :ok when valid" do
      token = <<0::160>>
      output = Fee.new_output(<<1::160>>, token, 1)
      {:ok, nonce} = Fee.build_nonce(%{blknum: 1000, token: token})
      tx = Builder.new(ExPlasma.fee(), nonce: nonce, outputs: [output])

      assert Fee.validate(tx) == :ok
    end

    test "returns an error when generic output is not valid" do
      output = Fee.new_output(<<1::160>>, <<0::160>>, 0)
      tx = Builder.new(ExPlasma.fee(), nonce: <<0>>, outputs: [output])

      assert_field(tx, :amount, :cannot_be_zero)
    end

    test "returns an error when outputs count is greater than 1" do
      outputs =
        Enum.reduce(1..6, [], fn i, acc ->
          [Fee.new_output(<<1::160>>, <<0::160>>, i) | acc]
        end)

      tx = Builder.new(ExPlasma.fee(), nonce: <<0>>, outputs: outputs)

      assert_field(tx, :outputs, :wrong_number_of_fee_outputs)
    end

    test "returns an error when outputs count is 0" do
      tx = Builder.new(ExPlasma.fee(), nonce: <<0>>, outputs: [])

      assert_field(tx, :outputs, :wrong_number_of_fee_outputs)
    end

    test "returns an error when output type is not a fee" do
      output = %Output{
        output_data: %{amount: 2, output_guard: <<2::160>>, token: <<0::160>>},
        output_id: nil,
        output_type: 1
      }

      tx = Builder.new(ExPlasma.fee(), nonce: <<0>>, outputs: [output])

      assert_field(tx, :outputs, :invalid_output_type_for_transaction)
    end

    test "returns an error when the nonce is not in the right format" do
      output = %Output{
        output_data: %{amount: 2, output_guard: <<2::160>>, token: <<0::160>>},
        output_id: nil,
        output_type: 2
      }

      tx = Builder.new(ExPlasma.fee(), nonce: <<0>>, outputs: [output])

      assert_field(tx, :nonce, :malformed_nonce)
    end
  end

  defp assert_field(data, field, message) do
    assert {:error, {^field, ^message}} = Fee.validate(data)
  end
end
