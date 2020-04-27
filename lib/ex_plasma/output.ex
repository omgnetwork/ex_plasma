defmodule ExPlasma.Output do
  @moduledoc """
  An Output.

  `output_id`   - The identifier scheme for the Output. We currently have two: Position and Id.
  `output_type` - An integer value of what type of output data is associated.
  `output_data` - The main data for the output. This can be decode by the different output types.
  """
  @type output_id() :: map() | nil
  @type output_type() :: non_neg_integer()
  @type output_data() :: map() | nil
  @type rlp() :: [output_type() | output_data()]

  @type t() :: %__MODULE__{
          output_id: output_id(),
          output_type: output_type(),
          output_data: output_data()
        }

  @type validation_responses() :: {:ok, map}

  # Output Types and Identifiers can implement these.
  @callback to_map(any()) :: map()
  @callback to_rlp(map()) :: any()
  @callback validate(any()) :: {:ok, map()} | {:error, {atom(), atom()}}

  # This maps to the various types of outputs
  # that we can have.
  #
  # Currently there is only 1 type.
  @output_types %{
    # NB: work-around the TypeData using a "zeroed-out" output to hash the eip712 struct with.
    0 => ExPlasma.Output.Type.PaymentV1,
    1 => ExPlasma.Output.Type.PaymentV1
  }

  defstruct output_id: nil, output_type: nil, output_data: nil

  @doc """
  Decode RLP data into an Output.

  ## Examples

  # Generate an Output from an RLP list

  iex> encoded = <<245, 1, 243, 148, 205, 193, 229, 59, 220, 116, 187, 245, 181, 247, 21, 214,
  ...> 50, 125, 202, 87, 133, 226, 40, 180, 148, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  ...> 0, 0, 0, 0, 0, 0, 0, 0, 136, 13, 224, 182, 179, 167, 100, 0, 0>>
  iex> ExPlasma.Output.decode(encoded)
  %ExPlasma.Output{
    output_data: %{
      amount: 1000000000000000000,
      output_guard: <<205, 193, 229, 59, 220, 116, 187, 245, 181, 247, 21, 214, 50, 125, 202, 87, 133, 226, 40, 180>>,
      token: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>},
    output_id: nil,
    output_type: 1
  }
  """
  @spec decode(rlp()) :: t()
  def decode(data) when is_list(data), do: do_decode(data)
  def decode(data), do: data |> ExRLP.decode() |> do_decode()

  @doc """

  ## Example

  iex> encoded_position = << 59, 154, 202, 0>>
  iex> ExPlasma.Output.decode_id(encoded_position)
  %ExPlasma.Output{
    output_data: nil,
    output_id: %{
      blknum: 1,
      oindex: 0,
      position: 1000000000,
      txindex: 0
    },
    output_type: nil
  }
  """
  def decode_id(data), do: data |> :binary.decode_unsigned(:big) |> do_decode()

  @doc """

  ## Examples

  # Encode as an Output

  iex> output = %ExPlasma.Output{
  ...>   output_data: %{
  ...>     amount: 1000000000000000000,
  ...>     output_guard: <<205, 193, 229, 59, 220, 116, 187, 245, 181, 247, 21, 214, 50, 125, 202, 87, 133, 226, 40, 180>>,
  ...>     token: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>},
  ...>   output_id: nil,
  ...>   output_type: 1
  ...> }
  iex> ExPlasma.Output.encode(output)
  <<245, 1, 243, 148, 205, 193, 229, 59, 220, 116, 187, 245, 181, 247, 21, 214,
  50, 125, 202, 87, 133, 226, 40, 180, 148, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 136, 13, 224, 182, 179, 167, 100, 0, 0>>

  # Encode as an Input

  iex> output = %ExPlasma.Output{
  ...>   output_data: nil,
  ...>   output_id: %{
  ...>     blknum: 1,
  ...>     oindex: 0,
  ...>     position: 1000000000,
  ...>     txindex: 0
  ...>   },
  ...>   output_type: nil
  ...> }
  iex> ExPlasma.Output.encode(output, as: :input)
  <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 59, 154, 202, 0>>
  """
  def encode(%{} = output, as: :input), do: to_rlp_id(output)
  def encode(%{} = output), do: output |> to_rlp() |> ExRLP.encode()

  @doc """
  Encode an Output into RLP bytes

  ## Example

  iex> output = %{
  ...>      output_id: nil,
  ...>      output_type: 1,
  ...>      output_data: %{output_guard: <<1::160>>, token: <<0::160>>, amount: 1}
  ...>    }
  iex> ExPlasma.Output.to_rlp(output)
  [<<1>>, [<<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1>>, <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>, <<1>>]]
  """
  @spec to_rlp(t()) :: binary()
  def to_rlp(%{output_type: nil}), do: nil
  def to_rlp(%{output_type: type} = output), do: get_output_type(type).to_rlp(output)

  @doc """
  Encodes an Output identifer into RLP bytes. This is to generate
  the `inputs` in a Transaction.

  ## Example
  """
  @spec to_rlp_id(t()) :: binary()
  def to_rlp_id(%{output_id: nil}), do: nil
  def to_rlp_id(%{output_id: id}), do: ExPlasma.Output.Position.to_rlp(id)

  @doc """
  Validates the Output

  ## Example

  # Validate a Payment v1 Output

  iex> encoded = <<245, 1, 243, 148, 205, 193, 229, 59, 220, 116, 187, 245, 181, 247, 21, 214,
  ...>  50, 125, 202, 87, 133, 226, 40, 180, 148, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  ...>  0, 0, 0, 0, 0, 0, 0, 0, 136, 13, 224, 182, 179, 167, 100, 0, 0>>
  iex> {:ok, output} = encoded |> ExPlasma.Output.decode() |> ExPlasma.Output.validate()

  # Validate a Output position

  iex> encoded_position = <<59, 154, 202, 0>>
  iex> {:ok, id} = encoded_position |> ExPlasma.Output.decode_id() |> ExPlasma.Output.validate()
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

  defp do_validate_id(%{output_id: %{} = output_id}),
    do: ExPlasma.Output.Position.validate(output_id)

  # Validate the output type and data. Bypass the validation if it doesn't
  # exist in the output body.
  defp do_validate_data(%{output_type: nil} = output), do: {:ok, output}

  defp do_validate_data(%{output_type: type} = output) when is_integer(type) do
    get_output_type(type).validate(output)
  end

  defp do_validate_data(%{output_type: <<type>>} = output) do
    get_output_type(type).validate(output)
  end

  # Generate our decoded output data based on the output type.
  defp do_decode([<<type>>, _data] = rlp) do
    struct(__MODULE__, get_output_type(type).to_map(rlp))
  end

  defp do_decode(pos) when is_integer(pos) do
    %__MODULE__{output_id: ExPlasma.Output.Position.to_map(pos)}
  end

  # Grabs the matching Output type by id. If it doesn't exist, use the empty type.
  defp get_output_type(type) do
    case Map.fetch(@output_types, type) do
      {:ok, output_type} ->
        output_type

      :error ->
        raise ArgumentError, message: "output type #{type} does not exist."
    end
  end
end
