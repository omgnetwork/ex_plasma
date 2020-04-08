defmodule ExPlasma.Output do
  @moduledoc false

  @type output_type() :: pos_integer()
  @type output_data() :: list()
  @type rlp() :: [output_type() | output_data()]

  @type id() :: map()

  @type t() :: %{
    output_id: id(),
    output_type: output_type(),
    output_data: output_data()
  }

  # Output Types and Identifiers can implement these.
  @callback decode(any()) :: map()
  @callback encode(map()) :: any()
  @callback validate(any()) :: {:ok, map()} | {:error, {atom(), atom()}}

  # This maps to the various types of outputs
  # that we can have.
  #
  # Currently there is only 1 type.
  #@output_types %{
    #1 =>
  #}

  #@doc """
  #Generate new Output.
  #"""
  #@spec new(t()) :: 
  #def new(), do: do_new(data)

  #defp do_new([<<output_type>>, output_data]), do: do_new([output_type, output_data])
  #defp do_new([output_type, output_data]), do: @output_types[output_type].build(output_data)

  ## Passing in output identifiers like positions
  #defp do_new(pos) when is_binary(pos) and byte_size(pos) <= 32, do: build_input(pos)
  #defp do_new(pos) when is_integer(pos), do: build_input(pos)
  #defp build_input(pos), do: ExPlasma.Output.Position.build(pos)







  #@doc """
  #Validates an Output.
  #"""

  #def validate(%{}), do: @output_types[output_type].validate(output_data)


  #defp unfurl_position(pos) do
    #blknum = div(utxo_pos, @block_offset)
    #txindex = utxo_pos |> rem(@block_offset) |> div(@transaction_offset)
    #oindex = rem(utxo_pos, @transaction_offset)

    #%{blknum: blknum, txindex: txindex, oindex: oindex}
  #end
end
