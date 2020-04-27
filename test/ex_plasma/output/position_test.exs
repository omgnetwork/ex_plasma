defmodule ExPlasma.Output.PositionTest do
  @moduledoc false
  use ExUnit.Case, async: true
  doctest ExPlasma.Output.Position

  alias ExPlasma.Output.Position

  describe "validate/1" do
    test "that blknum cannot be nil" do
      position = %{blknum: nil, txindex: 0, oindex: 0}
      assert_field(position, :blknum, :cannot_be_nil)
    end

    test "that blknum cannot exceed maximum value" do
      position = %{blknum: 1_000_000_000_000_000_000, txindex: 0, oindex: 0}
      assert_field(position, :blknum, :exceeds_maximum_value)
    end

    test "that txindex cannot be nil" do
      position = %{blknum: 0, txindex: nil, oindex: 0}
      assert_field(position, :txindex, :cannot_be_nil)
    end

    test "that txindex cannot exceed maximum value" do
      position = %{blknum: 0, txindex: 1_000_000_000_000_000_000, oindex: 0}
      assert_field(position, :txindex, :exceeds_maximum_value)
    end
  end

  defp assert_field(input, field, message) do
    assert {:error, {^field, ^message}} = Position.validate(input)
  end
end
