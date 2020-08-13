defmodule ExPlasma.Utils.RlpDecoderTest do
  use ExUnit.Case, async: true

  alias ExPlasma.Utils.RlpDecoder

  describe "decode/1" do
    test "returns {:ok, decoded} when valid" do
      assert {:ok, decoded} = 1 |> ExRLP.encode() |> RlpDecoder.decode()
      assert decoded == <<1>>
    end

    test "returns malformed_rlp when given invalid bytes" do
      assert RlpDecoder.decode(1) == {:error, :malformed_rlp}
    end
  end

  describe "parse_uint256/1" do
    test "rejects integer greater than 32-bytes" do
      large = 2.0 |> :math.pow(8 * 32) |> Kernel.trunc()
      [too_large] = [large] |> ExRLP.encode() |> ExRLP.decode()

      assert {:error, :encoded_uint_too_big} == RlpDecoder.parse_uint256(too_large)
    end

    test "rejects leading zeros encoded numbers" do
      [one] = [1] |> ExRLP.encode() |> ExRLP.decode()

      assert {:error, :leading_zeros_in_encoded_uint} == RlpDecoder.parse_uint256(<<0>> <> one)
    end

    test "rejects if not a binary" do
      assert {:error, :malformed_uint256} == RlpDecoder.parse_uint256(123)
    end

    test "accepts 32-bytes positive integers" do
      large = 2.0 |> :math.pow(8 * 32) |> Kernel.trunc()
      big_just_enough = large - 1

      [one, big] = [1, big_just_enough] |> ExRLP.encode() |> ExRLP.decode()

      assert {:ok, 1} == RlpDecoder.parse_uint256(one)
      assert {:ok, big_just_enough} == RlpDecoder.parse_uint256(big)
    end
  end
end
