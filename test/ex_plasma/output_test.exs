defmodule ExPlasma.OutputTest do
  use ExUnit.Case, async: true
  doctest ExPlasma.Output

  describe "validate/1" do
    test "validates output_id and output_data" do
      %{output_id: id} = ExPlasma.Output.new(1_000_000_000)

      output = %{
        output_id: id,
        output_type: 1,
        output_data: %{output_guard: <<1::160>>, token: <<0::160>>, amount: 1}
      }

      assert {:ok, ^output} = ExPlasma.Output.validate(output)
    end

    test "does not raise output_id errors if missing" do
      output = %{
        output_id: nil,
        output_type: 1,
        output_data: %{output_guard: <<1::160>>, token: <<0::160>>, amount: 0}
      }

      assert {:error, {:amount, :cannot_be_zero}} = ExPlasma.Output.validate(output)
    end

    test "does not raise output_type and output_data errors if missing" do
      %{output_id: id} = ExPlasma.Output.new(1_000_000_000_000_000_000_000)

      output = %{
        output_id: id,
        output_type: nil,
        output_data: []
      }

      assert {:error, {:blknum, :exceeds_maximum_value}} = ExPlasma.Output.validate(output)
    end

    test "validates id if type and data are valid" do
      %{output_id: id} = ExPlasma.Output.new(1_000_000_000_000_000_000_000)

      output = %{
        output_id: id,
        output_type: 1,
        output_data: %{output_guard: <<1::160>>, token: <<0::160>>, amount: 1}
      }

      assert {:error, {:blknum, :exceeds_maximum_value}} = ExPlasma.Output.validate(output)
    end
  end
end
