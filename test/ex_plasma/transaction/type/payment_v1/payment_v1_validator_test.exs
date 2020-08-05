defmodule ExPlasma.Transaction.Type.PaymentV1.ValidatorTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias ExPlasma.Output
  alias ExPlasma.Transaction.Type.PaymentV1
  alias ExPlasma.Transaction.Type.PaymentV1.Validator

  describe "validate_inputs/1" do
    test "returns :ok when valid" do
      inputs = [
        %Output{
          output_data: [],
          output_id: %{blknum: 0, oindex: 0, position: 0, txindex: 0},
          output_type: nil
        }
      ]

      assert Validator.validate_inputs(inputs) == :ok
    end

    test "returns an error when generic output is not valid" do
      inputs = [
        %Output{
          output_data: [],
          output_id: %{blknum: nil, oindex: 0, position: 0, txindex: 0},
          output_type: nil
        }
      ]

      assert Validator.validate_inputs(inputs) == {:error, {:blknum, :cannot_be_nil}}
    end

    test "returns an error when inputs are not unique" do
      input_1 = %Output{
        output_data: [],
        output_id: %{blknum: 0, oindex: 0, position: 0, txindex: 0},
        output_type: nil
      }

      input_2 = %Output{
        output_data: [],
        output_id: %{blknum: 0, oindex: 0, position: 0, txindex: 0},
        output_type: nil
      }

      assert Validator.validate_inputs([input_1, input_2]) == {:error, {:inputs, :duplicate_inputs}}
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

      assert Validator.validate_inputs(inputs) == {:error, {:inputs, :cannot_exceed_maximum_value}}
    end
  end

  describe "validate_outputs/1" do
    test "returns :ok when valid" do
      outputs = [
        PaymentV1.new_output(<<1::160>>, <<0::160>>, 10)
      ]

      assert Validator.validate_outputs(outputs) == :ok
    end

    test "returns an error when outputs count is greater than 4" do
      outputs =
        Enum.reduce(1..6, [], fn i, acc ->
          [PaymentV1.new_output(<<1::160>>, <<0::160>>, i) | acc]
        end)

      assert Validator.validate_outputs(outputs) == {:error, {:outputs, :cannot_exceed_maximum_value}}
    end

    test "returns an error when outputs count is 0" do
      assert Validator.validate_outputs([]) == {:error, {:outputs, :cannot_subceed_minimum_value}}
    end

    test "returns an error when output type is not a payment v1" do
      outputs = [
        %Output{
          output_data: %{amount: 2, output_guard: <<2::160>>, token: <<0::160>>},
          output_id: nil,
          output_type: 0
        }
      ]

      assert Validator.validate_outputs(outputs) == {:error, {:outputs, :invalid_output_type_for_transaction}}
    end
  end

  describe "validate_tx_data/1" do
    test "returns :ok when valid" do
      assert Validator.validate_tx_data(0) == :ok
    end

    test "returns an error when invalid" do
      assert Validator.validate_tx_data("1234") == {:error, {:tx_data, :malformed_tx_data}}
    end
  end

  describe "validate_metadata/1" do
    test "returns :ok when valid" do
      assert Validator.validate_metadata(<<0::256>>) == :ok
    end

    test "returns an error when length is not 256" do
      assert Validator.validate_metadata(<<0::254>>) == {:error, {:metadata, :malformed_metadata}}
    end

    test "returns an error when not a binary" do
      assert Validator.validate_metadata(123) == {:error, {:metadata, :malformed_metadata}}
    end
  end
end
