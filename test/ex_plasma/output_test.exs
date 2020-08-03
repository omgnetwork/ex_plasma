defmodule ExPlasma.OutputTest do
  use ExUnit.Case, async: true
  doctest ExPlasma.Output
  alias ExPlasma.Output

  describe "to_rlp/1" do
    test "returns an error for an invalid output type" do
      output = %Output{
        output_id: nil,
        output_type: 100,
        output_data: %{output_guard: <<1::160>>, token: <<0::160>>, amount: 1}
      }

      assert_raise ArgumentError, "output type 100 does not exist.", fn ->
        Output.to_rlp(output)
      end
    end

    test "returns nil if output_type is nil" do
      output = %Output{
        output_id: nil,
        output_type: nil,
        output_data: %{output_guard: <<1::160>>, token: <<0::160>>, amount: 1}
      }

      assert is_nil(Output.to_rlp(output))
    end

    test "converts to rlp" do
      output = %Output{
        output_data: %{
          amount: 1,
          output_guard: <<11, 246, 22, 41, 33, 46, 44, 159, 55, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110>>,
          token: <<46, 38, 45, 41, 28, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110>>
        },
        output_id: nil,
        output_type: 1
      }

      expected_result = [
        <<1>>,
        [
          <<11, 246, 22, 41, 33, 46, 44, 159, 55, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110>>,
          <<46, 38, 45, 41, 28, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110>>,
          <<1>>
        ]
      ]

      result = Output.to_rlp(output)

      assert result == expected_result
    end
  end

  describe "decode/1" do
    test "returns an exception  for an invalid output type" do
      assert_raise ArgumentError, "output type 10 does not exist.", fn ->
        Output.decode([<<10>>, []])
      end
    end

    test "decodes list output" do
      list_output = [
        <<1>>,
        [
          <<11, 246, 22, 41, 33, 46, 44, 159, 55, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110>>,
          <<46, 38, 45, 41, 28, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110>>,
          <<1>>
        ]
      ]

      result = Output.decode(list_output)

      expected_result = %Output{
        output_data: %{
          amount: 1,
          output_guard: <<11, 246, 22, 41, 33, 46, 44, 159, 55, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110>>,
          token: <<46, 38, 45, 41, 28, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110>>
        },
        output_id: nil,
        output_type: 1
      }

      assert result == expected_result
    end

    test "decodes rlp output" do
      rlp_output =
        ExRLP.encode([
          <<1>>,
          [
            <<11, 246, 22, 41, 33, 46, 44, 159, 55, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110>>,
            <<46, 38, 45, 41, 28, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110>>,
            <<1>>
          ]
        ])

      result = Output.decode(rlp_output)

      expected_result = %Output{
        output_data: %{
          amount: 1,
          output_guard: <<11, 246, 22, 41, 33, 46, 44, 159, 55, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110>>,
          token: <<46, 38, 45, 41, 28, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110>>
        },
        output_id: nil,
        output_type: 1
      }

      assert result == expected_result
    end
  end

  describe "decode_id/1" do
    test "decodes empty binary" do
      assert %Output{
               output_data: nil,
               output_id: %{blknum: 0, oindex: 0, position: 0, txindex: 0},
               output_type: nil
             } = Output.decode_id(<<>>)
    end
  end

  describe "encode/1" do
    test "encodes output" do
      output = %Output{
        output_data: %{
          amount: 1,
          output_guard: <<11, 246, 22, 41, 33, 46, 44, 159, 55, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110>>,
          token: <<46, 38, 45, 41, 28, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110>>
        },
        output_id: nil,
        output_type: 1
      }

      result = Output.encode(output)

      expected_result =
        <<237, 1, 235, 148, 11, 246, 22, 41, 33, 46, 44, 159, 55, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110,
          148, 46, 38, 45, 41, 28, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110, 1>>

      assert result == expected_result
    end

    test "encodes output as input" do
      %{output_id: id} = 1_000_000 |> ExRLP.encode() |> Output.decode_id()

      output = %Output{
        output_data: %{
          amount: 1,
          output_guard: <<11, 246, 22, 41, 33, 46, 44, 159, 55, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110>>,
          token: <<46, 38, 45, 41, 28, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110>>
        },
        output_id: id,
        output_type: 1
      }

      assert <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 131, 15, 66, 64>> ==
               Output.encode(output, as: :input)
    end
  end

  describe "to_rlp_id/1" do
    test "returns nil if output_id is nil" do
      output = %Output{
        output_data: nil,
        output_id: nil,
        output_type: 1
      }

      assert is_nil(Output.to_rlp_id(output))
    end

    test "returns rlp id" do
      %{output_id: id} = 1_000_000 |> ExRLP.encode() |> Output.decode_id()

      output = %Output{
        output_data: %{
          amount: 1,
          output_guard: <<11, 246, 22, 41, 33, 46, 44, 159, 55, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110>>,
          token: <<46, 38, 45, 41, 28, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110>>
        },
        output_id: id,
        output_type: 1
      }

      result = Output.to_rlp_id(output)

      expected_result =
        <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 131, 15, 66, 64>>

      assert result == expected_result
    end
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
