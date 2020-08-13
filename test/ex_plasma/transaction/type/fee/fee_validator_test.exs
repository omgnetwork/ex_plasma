defmodule ExPlasma.Transaction.Type.Fee.ValidatorTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias ExPlasma.Output
  alias ExPlasma.Transaction.Type.Fee
  alias ExPlasma.Transaction.Type.Fee.Validator

  describe "validate_outputs/1" do
    test "returns :ok when valid" do
      outputs = [
        Fee.new_output(<<1::160>>, <<0::160>>, 10)
      ]

      assert Validator.validate_outputs(outputs) == :ok
    end

    test "returns an error when generic output is not valid" do
      outputs = [
        Fee.new_output(<<1::160>>, <<0::160>>, 0)
      ]

      assert Validator.validate_outputs(outputs) == {:error, {:amount, :cannot_be_zero}}
    end

    test "returns an error when outputs count is greater than 1" do
      outputs =
        Enum.reduce(1..6, [], fn i, acc ->
          [Fee.new_output(<<1::160>>, <<0::160>>, i) | acc]
        end)

      assert Validator.validate_outputs(outputs) == {:error, {:outputs, :wrong_number_of_fee_outputs}}
    end

    test "returns an error when outputs count is 0" do
      assert Validator.validate_outputs([]) == {:error, {:outputs, :wrong_number_of_fee_outputs}}
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

  describe "validate_nonce/1" do
    test "returns :ok when valid" do
      assert Validator.validate_nonce(<<0::256>>) == :ok
    end

    test "returns an error when length is not 256" do
      assert Validator.validate_nonce(<<0::254>>) == {:error, {:nonce, :malformed_nonce}}
    end

    test "returns an error when the nonce is not a binary" do
      assert Validator.validate_nonce(1234) == {:error, {:nonce, :malformed_nonce}}
    end
  end
end
