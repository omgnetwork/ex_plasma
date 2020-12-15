defmodule ExPlasma.Output.Type.AbstractPaymentTest do
  @moduledoc false
  use ExUnit.Case, async: true
  doctest ExPlasma.Output.Type.AbstractPayment

  alias ExPlasma.Output.Type.AbstractPayment

  describe "to_rlp/1" do
    test "RLP encodes the given output" do
      amounts = [1, 65_000, 1_000_000_000_000_000_000_000_000]

      Enum.map(amounts, fn amount ->
        output = %{output_type: 1, output_data: %{output_guard: <<1::160>>, token: <<0::160>>, amount: amount}}
        encoded_amount = :binary.encode_unsigned(amount, :big)
        assert [_, [_, _, ^encoded_amount]] = AbstractPayment.to_rlp(output)
      end)
    end
  end

  describe "to_map/1" do
    test "maps a RLP list of items into an output for different amounts" do
      amounts = [1, 65_000, 1_000_000_000_000_000_000_000_000]

      Enum.map(amounts, fn amount ->
        rlp = [<<1>>, [<<0::160>>, <<0::160>>, :binary.encode_unsigned(amount, :big)]]

        assert {:ok, %{output_data: %{token: <<0::160>>, output_guard: <<0::160>>, amount: amount}}} =
                 AbstractPayment.to_map(rlp)
      end)
    end

    test "returns an error when output_guard is not a valid address" do
      invalid_output_guards = [<<0::80>>, "a", 123, []]

      Enum.map(invalid_output_guards, fn output_guard ->
        rlp = [<<1>>, [output_guard, <<0::160>>, <<1>>]]

        assert AbstractPayment.to_map(rlp) == {:error, :malformed_output_guard}
      end)
    end

    test "returns an error when token is not a valid address" do
      invalid_tokens = [<<0::80>>, "a", 123, []]

      Enum.map(invalid_tokens, fn token ->
        rlp = [<<1>>, [<<0::160>>, token, <<1>>]]

        assert AbstractPayment.to_map(rlp) == {:error, :malformed_output_token}
      end)
    end

    test "returns an error when amount is invalid" do
      invalid_amounts = [<<0::512>>, <<0::160>>, []]

      Enum.map(invalid_amounts, fn amount ->
        rlp = [<<1>>, [<<0::160>>, <<0::160>>, amount]]

        assert AbstractPayment.to_map(rlp) == {:error, :malformed_output_amount}
      end)
    end
  end

  describe "validate/1" do
    setup do
      output = %{
        output_data: %{
          amount: 1,
          output_guard: <<11, 246, 22, 41, 33, 46, 44, 159, 55, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110>>,
          token: <<46, 38, 45, 41, 28, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110>>
        },
        output_type: 1
      }

      {:ok, %{output: output}}
    end

    test "returns :ok when valid", %{output: output} do
      assert AbstractPayment.validate(output) == :ok
    end

    test "returns an error when amount is nil", %{output: output} do
      output = %{output | output_data: %{output.output_data | amount: nil}}
      assert_field(output, :amount, :cannot_be_nil)
    end

    test "returns an error when amount is zero", %{output: output} do
      output = %{output | output_data: %{output.output_data | amount: 0}}
      assert_field(output, :amount, :cannot_be_zero)
    end

    test "returns an error when token is nil", %{output: output} do
      output = %{output | output_data: %{output.output_data | token: nil}}
      assert_field(output, :token, :cannot_be_nil)
    end

    test "returns an error when output_guard is nil", %{output: output} do
      output = %{output | output_data: %{output.output_data | output_guard: nil}}
      assert_field(output, :output_guard, :cannot_be_nil)
    end

    test "returns an error when output_guard is zero", %{output: output} do
      output = %{output | output_data: %{output.output_data | output_guard: <<0::160>>}}
      assert_field(output, :output_guard, :cannot_be_zero)
    end
  end

  defp assert_field(data, field, message) do
    assert {:error, {^field, ^message}} = AbstractPayment.validate(data)
  end
end
