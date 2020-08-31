defmodule ExPlasma.OutputTest do
  use ExUnit.Case, async: true

  doctest ExPlasma.Output

  alias ExPlasma.Output
  alias ExPlasma.Transaction.TypeMapper

  @payment_output_type TypeMapper.output_type_for(:output_payment_v1)

  setup_all do
    output = %Output{
      output_data: %{
        amount: 1,
        output_guard: <<11, 246, 22, 41, 33, 46, 44, 159, 55, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110>>,
        token: <<46, 38, 45, 41, 28, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110>>
      },
      output_id: nil,
      output_type: 1
    }

    input = %Output{
      output_data: nil,
      output_id: %{
        blknum: 1,
        oindex: 0,
        txindex: 0,
        position: 1_000_000_000
      },
      output_type: nil
    }

    {:ok, encoded_input} = Output.encode(input, as: :input)
    {:ok, encoded_output} = Output.encode(output)

    {:ok,
     %{
       input: input,
       output: output,
       encoded_input: encoded_input,
       encoded_output: encoded_output
     }}
  end

  describe "decode/1" do
    test "successfuly decodes a valid encoded output", %{encoded_output: encoded_output, output: output} do
      assert Output.decode(encoded_output) == {:ok, output}
    end

    test "returns a malformed_output_rlp error when rlp is not decodable", %{encoded_output: encoded_output} do
      assert Output.decode("A" <> encoded_output) == {:error, :malformed_output_rlp}

      <<_, malformed_1::binary>> = encoded_output
      assert Output.decode(malformed_1) == {:error, :malformed_output_rlp}

      cropped_size = byte_size(encoded_output) - 1
      <<malformed_2::binary-size(cropped_size), _::binary-size(1)>> = encoded_output
      assert Output.decode(malformed_2) == {:error, :malformed_output_rlp}
    end

    test "returns a malformed_outputs error when rlp is decodable, but doesn't represent a known output format" do
      assert Output.decode(<<192>>) == {:error, :malformed_outputs}
      assert Output.decode(<<0x80>>) == {:error, :malformed_outputs}
      assert Output.decode(<<>>) == {:error, :malformed_outputs}
      assert Output.decode(ExRLP.encode(23)) == {:error, :malformed_outputs}
      assert Output.decode(ExRLP.encode([1])) == {:error, :malformed_outputs}
    end

    test "returns a unrecognized_transaction_type error when given an unkown/invalid output type" do
      assert Output.decode(ExRLP.encode([<<10>>, []])) == {:error, :unrecognized_output_type}
      assert Output.decode(ExRLP.encode([["bad"], []])) == {:error, :unrecognized_output_type}
      assert Output.decode(ExRLP.encode([234_567, []])) == {:error, :unrecognized_output_type}
    end

    test "forward decoding errors to sub-output types" do
      assert Output.decode(ExRLP.encode([@payment_output_type, [<<0::160>>, <<0::160>>, 'a']])) ==
               {:error, :malformed_output_amount}

      assert Output.decode(ExRLP.encode([@payment_output_type, [<<0::160>>, <<0::160>>, [1]]])) ==
               {:error, :malformed_output_amount}

      assert Output.decode(ExRLP.encode([@payment_output_type, [<<0::80>>, <<0::160>>, 1]])) ==
               {:error, :malformed_output_guard}

      assert Output.decode(ExRLP.encode([@payment_output_type, [<<0::160>>, <<0::80>>, 1]])) ==
               {:error, :malformed_output_token}
    end
  end

  describe "decode!/1" do
    test "successfuly decodes a valid encoded output", %{encoded_output: encoded_output, output: output} do
      assert Output.decode!(encoded_output) == output
    end

    test "raises when there was an error while decoding" do
      assert_raise MatchError, fn ->
        Output.decode!(<<192>>)
      end
    end
  end

  describe "decode_id/1" do
    test "successfuly decodes an encoded position", %{encoded_input: encoded_input, input: input} do
      assert Output.decode_id(encoded_input) == {:ok, input}
    end

    test "successfuly decodes empty binary" do
      assert Output.decode_id(<<>>) ==
               {:ok,
                %Output{
                  output_data: nil,
                  output_id: %{blknum: 0, oindex: 0, position: 0, txindex: 0},
                  output_type: nil
                }}
    end

    test "returns a malformed_input_position_rlp error when given malformated position" do
      assert Output.decode_id([]) ==
               {:error, :malformed_input_position_rlp}

      assert Output.decode_id(["q"]) ==
               {:error, :malformed_input_position_rlp}
    end
  end

  describe "decode_id!/1" do
    test "successfuly decodes a valid encoded position", %{encoded_input: encoded_input, input: input} do
      assert Output.decode_id!(encoded_input) == input
    end

    test "raises when there was an error while decoding" do
      assert_raise MatchError, fn ->
        Output.decode_id!([])
      end
    end
  end

  describe "to_map/1" do
    test "maps an rlp list of output data into an Output structure", %{output: output} do
      {:ok, rlp} = Output.to_rlp(output)

      assert {:ok, mapped} = Output.to_map(rlp)
      assert mapped == output
    end

    test "returns malformed_outputs error when the output is malformed" do
      assert Output.to_map(123) == {:error, :malformed_outputs}
      assert Output.to_map([]) == {:error, :malformed_outputs}
    end

    test "returns `unrecognized_output_type` when the given type is not supported" do
      assert Output.to_map([<<1337>>, []]) == {:error, :unrecognized_output_type}
    end
  end

  describe "to_map_id/1" do
    test "maps a position into an Output structure for an input", %{input: input} do
      assert Output.to_map_id(input.output_id.position) == {:ok, input}
    end

    test "returns an error when position is not an integer" do
      assert Output.to_map_id("bad") == {:error, :malformed_output_position}
    end
  end

  describe "encode/2" do
    test "encodes an output struct for an output", %{output: output} do
      assert {:ok, result} = Output.encode(output)

      expected_result =
        <<237, 1, 235, 148, 11, 246, 22, 41, 33, 46, 44, 159, 55, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110,
          148, 46, 38, 45, 41, 28, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110, 1>>

      assert result == expected_result
    end

    test "encodes an output struct for an input", %{input: input} do
      assert {:ok, result} = Output.encode(input, as: :input)

      assert result ==
               <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 59, 154, 202, 0>>
    end

    test "returns an error when output_type is nil for an output", %{input: input} do
      assert Output.encode(input) == {:error, :invalid_output_data}
    end

    test "returns an error when output_type is not valid for an output", %{output: output} do
      output = %Output{output | output_type: 9876}
      assert Output.encode(output) == {:error, :unrecognized_output_type}
    end

    test "returns an error when output_id is nil for an input", %{output: output} do
      assert Output.encode(output, as: :input) == {:error, :invalid_output_id}
    end
  end

  describe "to_rlp/1" do
    test "converts a valid output to rlp", %{output: output} do
      expected_result = [
        <<1>>,
        [
          <<11, 246, 22, 41, 33, 46, 44, 159, 55, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110>>,
          <<46, 38, 45, 41, 28, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110>>,
          <<1>>
        ]
      ]

      assert {:ok, result} = Output.to_rlp(output)

      assert result == expected_result
    end

    test "returns an error when given an invalid output_type" do
      output = %Output{
        output_id: nil,
        output_type: 100,
        output_data: %{output_guard: <<1::160>>, token: <<0::160>>, amount: 1}
      }

      assert Output.to_rlp(output) == {:error, :unrecognized_output_type}
    end

    test "returns an error when given a nil output_type", %{input: input} do
      assert Output.to_rlp(input) == {:error, :invalid_output_data}
    end
  end

  describe "to_rlp_id/1" do
    test "returns rlp id given a valid output position", %{input: input} do
      assert Output.to_rlp_id(input) ==
               {:ok,
                <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 59, 154, 202, 0>>}
    end

    test "returns an error if output_id is nil", %{output: output} do
      assert Output.to_rlp_id(output) == {:error, :invalid_output_id}
    end
  end

  describe "validate/1" do
    test "returns :ok when given a valid output", %{output: output} do
      assert Output.validate(output) == :ok
    end

    test "returns :ok when given a valid input", %{input: input} do
      assert Output.validate(input) == :ok
    end

    test "returns an error when output_type and output_id are missing" do
      output = %Output{}
      assert Output.validate(output) == {:error, {:output, :invalid_output}}
    end

    test "returns an error when output_type is invalid", %{output: output} do
      output = %Output{output | output_type: 9876}
      assert Output.validate(output) == {:error, {:output_type, :unrecognized_output_type}}
    end

    test "forward validation to sub-outputs for an output" do
      output = %Output{
        output_id: nil,
        output_type: 1,
        output_data: %{output_guard: <<1::160>>, token: <<0::160>>, amount: 0}
      }

      assert Output.validate(output) == {:error, {:amount, :cannot_be_zero}}
    end

    test "forward validation to sub-outputs for an input" do
      {:ok, input} = Output.to_map_id(1_000_000_000_000_000_000_000)

      assert Output.validate(input) == {:error, {:blknum, :cannot_exceed_maximum_value}}
    end
  end
end
