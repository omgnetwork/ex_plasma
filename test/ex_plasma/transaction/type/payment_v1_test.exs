defmodule ExPlasma.Transaction.Type.PaymentV1Test do
  @moduledoc false
  use ExUnit.Case, async: true
  doctest ExPlasma.Transaction.Type.PaymentV1, import: true

  alias ExPlasma.Builder
  alias ExPlasma.Output
  alias ExPlasma.Transaction
  alias ExPlasma.Transaction.Type.PaymentV1

  describe "new_output/3" do
    test "returns a new payment v1 output with the given params" do
      output = PaymentV1.new_output(<<0::160>>, <<0::160>>, 123)

      assert output == %Output{
               output_data: %{amount: 123, output_guard: <<0::160>>, token: <<0::160>>},
               output_id: nil,
               output_type: 1
             }
    end
  end

  describe "build_nonce/1" do
    test "returns a nil nonce" do
      assert PaymentV1.build_nonce(%{}) == {:ok, nil}
    end
  end

  describe "to_rlp/1" do
    test "returns the rlp item list of the given payment v1 transaction" do
      input = %Output{
        output_data: [],
        output_id: %{blknum: 1, oindex: 2, txindex: 3, position: 1_000_020_003},
        output_type: nil
      }

      output = PaymentV1.new_output(<<1::160>>, <<0::160>>, 1)
      tx = Builder.new(ExPlasma.payment_v1(), inputs: [input], outputs: [output])

      assert {:ok, rlp} = PaymentV1.to_rlp(tx)

      assert rlp == [
               # tx type
               <<1>>,
               [
                 # input position
                 <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 59, 155, 63, 50>>
               ],
               [
                 [
                   # Output type
                   <<1>>,
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
               # tx data
               0,
               # metadata
               <<0::256>>
             ]
    end
  end

  describe "to_map/1" do
    test "returns a transaction struct from an rlp list when valid" do
      rlp = [
        # tx type
        <<1>>,
        [
          # input position
          <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 59, 155, 63, 50>>
        ],
        [
          [
            # Output type
            <<1>>,
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
        # tx data
        <<0>>,
        # metadata
        <<0::256>>
      ]

      assert {:ok, tx} = PaymentV1.to_map(rlp)

      assert tx == %Transaction{
               inputs: [
                 %Output{
                   output_data: nil,
                   output_id: %{blknum: 1, oindex: 2, position: 1_000_030_002, txindex: 3},
                   output_type: nil
                 }
               ],
               metadata: <<0::256>>,
               outputs: [
                 %Output{
                   output_data: %{amount: 1, output_guard: <<1::160>>, token: <<0::160>>},
                   output_id: nil,
                   output_type: 1
                 }
               ],
               tx_data: 0,
               tx_type: 1,
               sigs: [],
               witnesses: []
             }
    end

    test "returns a `malformed_transaction` error when the rlp is invalid" do
      assert PaymentV1.to_map([<<1>>, <<1>>]) == {:error, :malformed_transaction}
    end

    test "returns a `malformed_tx_data` error when the tx data is invalid" do
      assert PaymentV1.to_map([<<1>>, [], [], <<0, 1>>, <<0::256>>]) == {:error, :malformed_tx_data}
    end

    test "returns a `malformed_input_position_rlp` error when the inputs are not a list" do
      assert PaymentV1.to_map([<<1>>, 123, [], <<0>>, <<0::256>>]) == {:error, :malformed_input_position_rlp}
    end

    test "returns a `malformed_input_position_rlp` error when the inputs are not an encoded position" do
      assert PaymentV1.to_map([<<1>>, [123, 123], [], <<0>>, <<0::256>>]) == {:error, :malformed_input_position_rlp}
    end

    test "returns a `malformed_output_rlp` error when the outputs are not a list" do
      assert PaymentV1.to_map([<<1>>, [], 123, <<0>>, <<0::256>>]) == {:error, :malformed_output_rlp}
    end

    test "returns a `malformed_outputs` error when the outputs are not an encoded output data" do
      assert PaymentV1.to_map([<<1>>, [], [123], <<0>>, <<0::256>>]) == {:error, :malformed_outputs}
    end

    test "returns a `malformed_metadata` error when metadata is not a 32 bytes binary" do
      assert PaymentV1.to_map([<<1>>, [], [], <<0>>, 123]) == {:error, :malformed_metadata}
    end
  end

  describe "validate/1" do
    test "returns :ok when valid" do
      input_1 = %Output{
        output_data: nil,
        output_id: %{blknum: 1, oindex: 2, position: 1_000_030_002, txindex: 3},
        output_type: nil
      }

      input_2 = %Output{
        output_data: nil,
        output_id: %{blknum: 1, oindex: 3, position: 1_000_030_003, txindex: 3},
        output_type: nil
      }

      output_1 = PaymentV1.new_output(<<1::160>>, <<0::160>>, 1)
      output_2 = PaymentV1.new_output(<<1::160>>, <<0::160>>, 2)
      output_3 = PaymentV1.new_output(<<2::160>>, <<0::160>>, 3)

      tx = Builder.new(ExPlasma.payment_v1(), inputs: [input_1, input_2], outputs: [output_1, output_2, output_3])

      assert PaymentV1.validate(tx) == :ok
    end

    test "returns an error when generic output is not valid" do
      output = PaymentV1.new_output(<<1::160>>, <<0::160>>, 0)
      tx = Builder.new(ExPlasma.payment_v1(), inputs: [], outputs: [output])

      assert_field(tx, :amount, :cannot_be_zero)
    end

    test "returns an error when inputs are not unique" do
      input = %Output{
        output_data: [],
        output_id: %{blknum: 0, oindex: 0, position: 0, txindex: 0},
        output_type: nil
      }

      tx = Builder.new(ExPlasma.payment_v1(), inputs: [input, input], outputs: [])

      assert_field(tx, :inputs, :duplicate_inputs)
    end

    test "returns an error when inputs count is greater than 4" do
      inputs =
        Enum.reduce(0..5, [], fn i, acc ->
          [
            %Output{
              output_data: [],
              output_id: %{blknum: i, oindex: 0, position: 0, txindex: 0},
              output_type: nil
            }
            | acc
          ]
        end)

      output = PaymentV1.new_output(<<1::160>>, <<0::160>>, 0)

      tx = Builder.new(ExPlasma.payment_v1(), inputs: inputs, outputs: [output])

      assert_field(tx, :inputs, :cannot_exceed_maximum_value)
    end

    test "returns an error when outputs count is greater than 4" do
      outputs =
        Enum.reduce(1..6, [], fn i, acc ->
          [PaymentV1.new_output(<<1::160>>, <<0::160>>, i) | acc]
        end)

      tx = Builder.new(ExPlasma.payment_v1(), inputs: [], outputs: outputs)

      assert_field(tx, :outputs, :cannot_exceed_maximum_value)
    end

    test "returns an error when outputs count is 0" do
      tx = Builder.new(ExPlasma.payment_v1(), inputs: [], outputs: [])

      assert_field(tx, :outputs, :cannot_subceed_minimum_value)
    end

    test "returns an error when output type is valid but not a payment v1" do
      output = %Output{
        output_data: %{amount: 2, output_guard: <<2::160>>, token: <<0::160>>},
        output_id: nil,
        output_type: 0
      }

      tx = Builder.new(ExPlasma.payment_v1(), inputs: [], outputs: [output])

      assert_field(tx, :outputs, :invalid_output_type_for_transaction)
    end

    test "returns an error when output type is invalid" do
      output = %Output{
        output_data: %{amount: 2, output_guard: <<2::160>>, token: <<0::160>>},
        output_id: nil,
        output_type: 98_123_983
      }

      tx = Builder.new(ExPlasma.payment_v1(), inputs: [], outputs: [output])
      assert_field(tx, :output_type, :unrecognized_output_type)
    end
  end

  defp assert_field(data, field, message) do
    assert {:error, {^field, ^message}} = PaymentV1.validate(data)
  end
end
