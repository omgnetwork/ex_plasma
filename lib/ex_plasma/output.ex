defmodule ExPlasma.Output do
  @moduledoc """
  An Output.

  `output_id` - the Identifier scheme for the Output. We currently have two: Position and Id.
  `output_type` - An integer value of what type of output data is associated.
  `output_data` - The main data for the output. This can be decode by the different output types.
  """

  @type output_type() :: pos_integer()
  @type output_data() :: list()
  @type rlp() :: [output_type() | output_data()]

  @type id() :: map()

  @type t() :: %{
    output_id: id(),
    output_type: output_type(),
    output_data: output_data()
  }

  @type validation_responses() :: {:ok, map}

  # Output Types and Identifiers can implement these.
  @callback decode(any()) :: map()
  @callback encode(map()) :: any()
  @callback validate(any()) :: {:ok, map()} | {:error, {atom(), atom()}}

  # This maps to the various types of outputs
  # that we can have.
  #
  # Currently there is only 1 type.
  @output_types %{
    1 => ExPlasma.Output.Type.PaymentV1
  }

  @doc """
  Generate new Output.

  ## Examples

  # Generate an Output from an RLP list

  iex> data = [<<205, 193, 229, 59, 220, 116, 187, 245, 181, 247, 21, 214, 50, 125, 202, 87, 133, 226, 40, 180>>, <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>, <<13, 224, 182, 179, 167, 100, 0, 0>>]
  iex> rlp = [ExPlasma.payment_v1(), data]
  iex> ExPlasma.Output.new(rlp)
  %{output_data: %{amount: <<13, 224, 182, 179, 167, 100, 0, 0>>, output_guard: <<205, 193, 229, 59, 220, 116, 187, 245, 181, 247, 21, 214, 50, 125, 202, 87, 133, 226, 40, 180>>, token: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>}, output_id: nil, output_type: 1}

  # Generate an Output from a position.
  iex> ExPlasma.Output.new(1_000_000_000)
  %{output_data: [], output_id: %{blknum: 1, oindex: 0, position: 1000000000, txindex: 0}, output_type: nil}
  """
  @spec new(rlp()) :: t()
  def new(data), do: do_new(data)

  @doc """
  Validates the Output

  ## Example

  # Validate a Payment v1 Output

  iex> data = [<<205, 193, 229, 59, 220, 116, 187, 245, 181, 247, 21, 214, 50, 125, 202, 87, 133, 226, 40, 180>>, <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>, <<13, 224, 182, 179, 167, 100, 0, 0>>]
  iex> rlp = [ExPlasma.payment_v1(), data]
  iex> {:ok, output} = rlp |> ExPlasma.Output.new() |> ExPlasma.Output.validate()

  # Validate a Output position

  iex> position =  1_000_000_000
  iex> {:ok, id} = position |> ExPlasma.Output.new() |> ExPlasma.Output.validate()
  """
  @spec validate(t()) :: validation_responses()
  def validate(%{} = output) do
    with {:ok, _data} <- do_validate_data(output),
         {:ok, _id} <- do_validate_id(output) do
      {:ok, output}
    end
  end

  # Validate the output ID. Bypass the validation if it doesn't
  # exist in the output body.
  defp do_validate_id(%{output_id: nil} = output), do: {:ok, output}
  defp do_validate_id(%{output_id: %{} = output_id}), do: ExPlasma.Output.Position.validate(output_id)

  # Validate the output type and data. Bypass the validation if it doesn't
  # exist in the output body.
  defp do_validate_data(%{output_type: nil, output_data: []} = output), do: {:ok, output}
  defp do_validate_data(%{output_type: type, output_data: data}), do: @output_types[type].validate(data)

  # Generate our decoded output data based on the output type.
  defp do_new([<<output_type>>, output_data]), do: do_new([output_type, output_data])

  defp do_new([output_type, output_data]) do
    %{
      output_id: nil,
      output_type: output_type,
      output_data: @output_types[output_type].decode(output_data)
    }
  end

  # Passing in output identifiers like positions
  defp do_new(pos) when is_binary(pos) and byte_size(pos) <= 32,
    do: pos |> :binary.decode_unsigned(:big) |> build_position()

  defp do_new(pos) when is_integer(pos), do: build_position(pos)

  defp build_position(pos) do
    %{
      output_id: ExPlasma.Output.Position.decode(pos),
      output_type: nil,
      output_data: []
    }
  end
end
