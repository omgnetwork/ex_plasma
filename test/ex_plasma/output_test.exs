defmodule ExPlasma.OutputTest do
  use ExUnit.Case, async: true
  doctest ExPlasma.Output
  alias ExPlasma.Output

  test "to_rlp/1 returns an error for an invalid output type" do
    output = %Output{
      output_id: nil,
      output_type: 100,
      output_data: %{output_guard: <<1::160>>, token: <<0::160>>, amount: 1}
    }

    assert_raise ArgumentError, "output type 100 does not exist.", fn ->
      ExPlasma.Output.to_rlp(output)
    end
  end

  test "decode/1 returns an empty map for an invalid output type" do
    ExRLP.encode([<<0>>, []])
  end

  describe "validate/1" do
    test "validates output_id and output_data" do
      %{output_id: id} = 1_000_000 |> ExRLP.encode() |> Output.decode_id()

      output = %Output{
        output_id: id,
        output_type: 1,
        output_data: %{output_guard: <<1::160>>, token: <<0::160>>, amount: 1}
      }

      assert {:ok, ^output} = ExPlasma.Output.validate(output)
    end

    test "does not raise output_id errors if missing" do
      output = %Output{
        output_id: nil,
        output_type: 1,
        output_data: %{output_guard: <<1::160>>, token: <<0::160>>, amount: 0}
      }

      assert {:error, {:amount, :cannot_be_zero}} = ExPlasma.Output.validate(output)
    end

    test "does not raise output_type and output_data errors if missing" do
      %Output{output_id: id} =
        1_000_000_000_000_000_000_000
        |> ExRLP.encode()
        |> Output.decode_id()

      output = %Output{
        output_id: id,
        output_type: nil,
        output_data: nil
      }

      assert {:error, {:blknum, :cannot_exceed_maximum_value}} = ExPlasma.Output.validate(output)
    end

    test "validates id if type and data are valid" do
      %Output{output_id: id} =
        1_000_000_000_000_000_000_000
        |> ExRLP.encode()
        |> Output.decode_id()

      output = %Output{
        output_id: id,
        output_type: 1,
        output_data: %{output_guard: <<1::160>>, token: <<0::160>>, amount: 1}
      }

      assert {:error, {:blknum, :cannot_exceed_maximum_value}} = ExPlasma.Output.validate(output)
    end
  end
end
