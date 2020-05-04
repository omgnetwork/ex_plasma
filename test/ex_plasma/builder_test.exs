defmodule ExPlasma.BuilderTest do
  use ExUnit.Case, async: true
  doctest ExPlasma.Builder, import: true

  import ExPlasma.Builder

  test "builds a transaction with both inputs and outputs" do
    txn =
      [tx_type: 1, metadata: <<1::160>>, tx_data: 0]
      |> new()
      |> add_input(blknum: 1, txindex: 0, oindex: 0)
      |> add_input(blknum: 2, txindex: 1, oindex: 0)
      |> add_input(blknum: 3, txindex: 0, oindex: 1)
      |> add_output(
        output_type: 1,
        output_data: %{output_guard: <<1::160>>, token: <<0::160>>, amount: 1}
      )
      |> add_output(output_guard: <<1::160>>, token: <<0::160>>, amount: 1)
      |> add_output(output_guard: <<2::160>>, token: <<0::160>>, amount: 2)

    assert txn == %ExPlasma.Transaction{
             inputs: [
               %ExPlasma.Output{
                 output_data: nil,
                 output_id: %{blknum: 1, oindex: 0, txindex: 0},
                 output_type: nil
               },
               %ExPlasma.Output{
                 output_data: nil,
                 output_id: %{blknum: 2, oindex: 0, txindex: 1},
                 output_type: nil
               },
               %ExPlasma.Output{
                 output_data: nil,
                 output_id: %{blknum: 3, oindex: 1, txindex: 0},
                 output_type: nil
               }
             ],
             metadata: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1>>,
             outputs: [
               %ExPlasma.Output{
                 output_data: %{
                   amount: 1,
                   output_guard: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1>>,
                   token: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>
                 },
                 output_id: nil,
                 output_type: 1
               },
               %ExPlasma.Output{
                 output_data: %{
                   amount: 1,
                   output_guard: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1>>,
                   token: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>
                 },
                 output_id: nil,
                 output_type: 1
               },
               %ExPlasma.Output{
                 output_data: %{
                   amount: 2,
                   output_guard: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2>>,
                   token: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>
                 },
                 output_id: nil,
                 output_type: 1
               }
             ],
             sigs: [],
             tx_data: 0,
             tx_type: 1
           }
  end
end
