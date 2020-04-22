defmodule ExPlasma.Transaction2Test do
  @moduledoc false
  use ExUnit.Case, async: true
  doctest ExPlasma.Transaction2

  alias ExPlasma.Transaction2

  describe "validate/1" do
    test "that the inputs in a transaction have valid positions" do
      bad_position =
        1_000_000_000_000_000_000_000
        |> :binary.encode_unsigned(:big)
        |> ExPlasma.Output.decode_id()

      txn = %{
        inputs: [bad_position],
        metadata: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
        outputs: [
          %{
            output_data: %{
              amount: 1,
              output_guard:
                <<29, 246, 47, 41, 27, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241,
                  55, 0, 110>>,
              token:
                <<46, 38, 45, 41, 28, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241,
                  55, 0, 110>>
            },
            output_id: nil,
            output_type: 1
          }
        ],
        sigs: [],
        tx_data: <<0>>,
        tx_type: <<1>>
      }

      assert_field(txn, :blknum, :exceeds_maximum_value)
    end

    test "that the outputs in a transaction are valid outputs" do
      # zero amount output
      bad_output = ExPlasma.Output.decode([<<1>>, [<<1::160>>, <<0::160>>, <<0>>]])

      txn = %{
        inputs: [],
        metadata: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
        outputs: [bad_output],
        sigs: [],
        tx_data: <<0>>,
        tx_type: <<1>>
      }

      assert_field(txn, :amount, :cannot_be_zero)
    end
  end

  defp assert_field(data, field, message) do
    assert {:error, {^field, ^message}} = Transaction2.validate(data)
  end
end
