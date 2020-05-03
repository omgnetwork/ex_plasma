defmodule ExPlasma.Transaction.Type.PaymentV1Test do
  @moduledoc false
  use ExUnit.Case, async: true
  doctest ExPlasma.Transaction.Type.PaymentV1

  alias ExPlasma.Output
  alias ExPlasma.Transaction.Type.PaymentV1

  describe "validate/1" do
    test "that inputs cannot be greater than 4" do
      input = %Output{
        output_data: [],
        output_id: %{blknum: 0, oindex: 0, position: 0, txindex: 0},
        output_type: nil
      }

      txn = %ExPlasma.Transaction{
        inputs: [input, input, input, input, input],
        metadata: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
        outputs: [
          %Output{
            output_data: %{
              amount: <<0, 0, 0, 0, 0, 0, 0, 1>>,
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

      assert_field(txn, :inputs, :cannot_exceed_maximum_value)
    end

    test "that outputs cannot be greater than 4" do
      output = %Output{
        output_data: %{
          amount: <<0, 0, 0, 0, 0, 0, 0, 1>>,
          output_guard:
            <<29, 246, 47, 41, 27, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55,
              0, 110>>,
          token:
            <<46, 38, 45, 41, 28, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0,
              110>>
        },
        output_id: nil,
        output_type: 1
      }

      txn = %{
        inputs: [
          %Output{
            output_data: [],
            output_id: %{blknum: 0, oindex: 0, position: 0, txindex: 0},
            output_type: nil
          }
        ],
        metadata: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
        outputs: [output, output, output, output, output],
        sigs: [],
        tx_data: <<0>>,
        tx_type: <<1>>
      }

      assert_field(txn, :outputs, :cannot_exceed_maximum_value)
    end

    test "that outputs cannot be less than 1" do
      txn = %{
        inputs: [
          %Output{
            output_data: [],
            output_id: %{blknum: 0, oindex: 0, position: 0, txindex: 0},
            output_type: nil
          }
        ],
        metadata: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
        outputs: [],
        sigs: [],
        tx_data: <<0>>,
        tx_type: <<1>>
      }

      assert_field(txn, :outputs, :cannot_subceed_minimum_value)
    end
  end

  defp assert_field(data, field, message) do
    assert {:error, {^field, ^message}} = PaymentV1.validate(data)
  end
end
