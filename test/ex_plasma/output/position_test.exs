defmodule ExPlasma.Output.PositionTest do
  @moduledoc false
  use ExUnit.Case, async: true
  doctest ExPlasma.Output.Position

  alias ExPlasma.Output.Position

  describe "new/3" do
    test "creates an output_id" do
      assert Position.new(1, 2, 3) == %{blknum: 1, oindex: 3, position: 1_000_020_003, txindex: 2}
    end
  end

  describe "pos/1" do
    test "returns the position" do
      output_id = %{blknum: 1, txindex: 2, oindex: 3}
      assert Position.pos(output_id) == 1_000_020_003
    end
  end

  describe "to_rlp/1" do
    test "returns the encoded position from an output struct" do
      output_id = %{blknum: 1, txindex: 2, oindex: 3}
      result = Position.to_rlp(output_id)

      expected_result =
        <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 59, 155, 24, 35>>

      assert result == expected_result
    end
  end

  describe "encode/1" do
    test "returns the encoded position from a position" do
      result = Position.encode(1_000_020_003)

      expected_result =
        <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 59, 155, 24, 35>>

      assert result == expected_result
    end
  end

  describe "to_map/1" do
    test "returns an Output struct from the given position" do
      assert Position.to_map(1_000_020_003) == {:ok, %{blknum: 1, oindex: 3, position: 1_000_020_003, txindex: 2}}
    end
  end

  describe "decode/1" do
    test "returns the decoded position from the given binary" do
      encoded = <<59, 155, 24, 35>>
      assert Position.decode(encoded) == {:ok, 1_000_020_003}
    end

    test "returns an error when the given position is invalid" do
      assert Position.decode([]) == {:error, :malformed_input_position_rlp}
    end
  end

  describe "validate/1" do
    setup do
      output_id = %{blknum: 1, oindex: 3, position: 1_000_020_003, txindex: 2}

      {:ok, %{output_id: output_id}}
    end

    test "returns :ok when valid", %{output_id: output_id} do
      assert Position.validate(output_id) == :ok
    end

    test "returns an error when blknum is nil", %{output_id: output_id} do
      output_id = %{output_id | blknum: nil}
      assert_field(output_id, :blknum, :cannot_be_nil)
    end

    test "returns an error when blknum exceed maximum value", %{output_id: output_id} do
      output_id = %{output_id | blknum: 1_000_000_000_000_000_000}
      assert_field(output_id, :blknum, :cannot_exceed_maximum_value)
    end

    test "returns an error when blknum is not an integer", %{output_id: output_id} do
      output_id = %{output_id | blknum: "a"}
      assert_field(output_id, :blknum, :must_be_an_integer)
    end

    test "returns an error when txindex is nil", %{output_id: output_id} do
      output_id = %{output_id | txindex: nil}
      assert_field(output_id, :txindex, :cannot_be_nil)
    end

    test "returns an error when txindex exceed maximum value", %{output_id: output_id} do
      output_id = %{output_id | txindex: 1_000_000_000_000_000_000}
      assert_field(output_id, :txindex, :cannot_exceed_maximum_value)
    end

    test "returns an error when txindex is not an integer", %{output_id: output_id} do
      output_id = %{output_id | txindex: "a"}
      assert_field(output_id, :txindex, :must_be_an_integer)
    end

    test "returns an error when oindex is nil", %{output_id: output_id} do
      output_id = %{output_id | oindex: nil}
      assert_field(output_id, :oindex, :cannot_be_nil)
    end

    test "returns an error when oindex is not an integer", %{output_id: output_id} do
      output_id = %{output_id | oindex: "a"}
      assert_field(output_id, :oindex, :must_be_an_integer)
    end
  end

  defp assert_field(data, field, message) do
    assert {:error, {^field, ^message}} = Position.validate(data)
  end
end
