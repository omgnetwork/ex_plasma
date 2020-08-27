defmodule ExPlasma.Output do
  @moduledoc """
  An Output.

  `output_id`   - The identifier scheme for the Output. We currently have two: Position and Id.
  `output_type` - An integer value of what type of output data is associated.
  `output_data` - The main data for the output. This can be decode by the different output types.
  """

  alias ExPlasma.Output.Position
  alias ExPlasma.Transaction.TypeMapper
  alias ExPlasma.Utils.RlpDecoder

  @type output_id() :: map() | nil
  @type output_type() :: non_neg_integer() | nil
  @type output_data() :: map() | nil
  @type rlp() :: [output_type() | output_data()]

  @type t() :: %__MODULE__{
          output_id: output_id(),
          output_type: output_type(),
          output_data: output_data()
        }

  @type input_position() :: %__MODULE__{
          output_id: Position.t(),
          output_type: nil,
          output_data: nil
        }

  @type output() :: %__MODULE__{
          output_id: nil,
          output_type: output_type(),
          output_data: output_data()
        }

  @type decoding_error() :: :malformed_output_rlp | mapping_error()
  @type mapping_error() :: :malformed_outputs | :unrecognized_output_type | atom()
  @type validation_responses() :: :ok | validation_errors()
  @type validation_errors() :: {:error, {atom(), atom()}}

  # Output Types and Identifiers should implement these.
  @callback to_map(any()) :: {:ok, map()} | {:error, atom()}
  @callback to_rlp(map()) :: list() | binary()
  @callback validate(map()) :: validation_responses()

  @output_types_modules TypeMapper.output_type_modules()

  defstruct output_id: nil, output_type: nil, output_data: nil

  @doc """
  Decode RLP data into an Output.

  ## Examples

  # Generate an Output from an RLP list

  iex> encoded = <<245, 1, 243, 148, 205, 193, 229, 59, 220, 116, 187, 245, 181, 247, 21, 214,
  ...> 50, 125, 202, 87, 133, 226, 40, 180, 148, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  ...> 0, 0, 0, 0, 0, 0, 0, 0, 136, 13, 224, 182, 179, 167, 100, 0, 0>>
  iex> ExPlasma.Output.decode(encoded)
  {:ok, %ExPlasma.Output{
    output_data: %{
      amount: 1000000000000000000,
      output_guard: <<205, 193, 229, 59, 220, 116, 187, 245, 181, 247, 21, 214, 50, 125, 202, 87, 133, 226, 40, 180>>,
      token: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>},
    output_id: nil,
    output_type: 1
  }}
  """
  @spec decode(binary()) :: {:ok, output()} | {:error, decoding_error()}
  def decode(data) do
    case RlpDecoder.decode(data) do
      {:ok, rlp} -> to_map(rlp)
      {:error, :malformed_rlp} -> {:error, :malformed_output_rlp}
    end
  end

  @doc """
  Throwing version of decode/1
  """
  @spec decode!(binary()) :: output() | no_return()
  def decode!(data) do
    {:ok, output} = decode(data)
    output
  end

  @doc """
  Decode RLP input position into an Output.

  ## Example

  iex> encoded_position = <<59, 154, 202, 0>>
  iex> ExPlasma.Output.decode_id(encoded_position)
  {:ok, %ExPlasma.Output{
    output_data: nil,
    output_id: %{
      blknum: 1,
      oindex: 0,
      position: 1000000000,
      txindex: 0
    },
    output_type: nil
  }}
  """
  @spec decode_id(binary()) :: {:ok, input_position()} | {:error, :malformed_input_position_rlp}
  def decode_id(data) do
    with {:ok, pos} <- Position.decode(data),
         {:ok, output_id} <- Position.to_map(pos) do
      {:ok, %__MODULE__{output_id: output_id}}
    end
  end

  @doc """
  Throwing version of decode_id/1
  """
  @spec decode_id!(binary()) :: input_position() | no_return()
  def decode_id!(data) do
    {:ok, output} = decode_id(data)
    output
  end

  @doc """
  Maps the given RLP list into an output.

  The RLP list must start with the output type and follow with its data.

  ## Examples

  iex> rlp = [
  ...>  <<1>>,
  ...>  [
  ...>    <<11, 246, 22, 41, 33, 46, 44, 159, 55, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110>>,
  ...>    <<46, 38, 45, 41, 28, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110>>,
  ...>    <<1>>
  ...>  ]
  ...>]
  iex> ExPlasma.Output.to_map(rlp)
  {:ok,
    %ExPlasma.Output{
      output_data: %{
        amount: 1,
        output_guard: <<11, 246, 22, 41, 33, 46, 44, 159, 55, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110>>,
        token: <<46, 38, 45, 41, 28, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110>>
      },
      output_id: nil,
      output_type: 1}
  }

  Only validates that the RLP is structurally correct.
  Does not perform any other kind of validation, use validate/1 for that.
  """
  @spec to_map(list()) :: {:ok, output()} | {:error, mapping_error()}
  def to_map([raw_output_type | _output_rlp_items] = rlp) do
    with {:ok, output_module} <- parse_output_type(raw_output_type),
         {:ok, output_data} <- output_module.to_map(rlp) do
      {:ok, struct(__MODULE__, output_data)}
    end
  end

  def to_map(_), do: {:error, :malformed_outputs}

  @doc """
  Maps the given integer position into an output.

  ## Examples

  iex> pos = 1_000_000_000
  iex> ExPlasma.Output.to_map_id(pos)
  {:ok, %ExPlasma.Output{output_id: %{position: 1_000_000_000, blknum: 1, txindex: 0, oindex: 0}}}

  Only validates that the RLP is structurally correct.
  Does not perform any other kind of validation, use validate/1 for that.
  """
  @spec to_map_id(Position.position()) :: {:ok, input_position()} | {:error, :malformed_output_position}
  def to_map_id(position) do
    case Position.to_map(position) do
      {:ok, output_id} -> {:ok, %__MODULE__{output_id: output_id}}
      error -> error
    end
  end

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
  {:ok, <<245, 1, 243, 148, 205, 193, 229, 59, 220, 116, 187, 245, 181, 247, 21, 214,
  50, 125, 202, 87, 133, 226, 40, 180, 148, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 136, 13, 224, 182, 179, 167, 100, 0, 0>>}

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
  {:ok, <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 59, 154, 202, 0>>}
  """
  @spec encode(t() | list()) ::
          {:ok, binary()} | {:error, :invalid_output_id | :invalid_output_data | :unrecognized_output_type}
  def encode(%__MODULE__{} = output, as: :input), do: to_rlp_id(output)

  def encode(%__MODULE__{} = output) do
    with {:ok, rlp} <- to_rlp(output),
         {:ok, encoded} <- encode(rlp) do
      {:ok, encoded}
    end
  end

  def encode(rlp_items), do: {:ok, ExRLP.encode(rlp_items)}

  @doc """
  Encode an Output into RLP bytes

  ## Example

  iex> output = %ExPlasma.Output{
  ...>      output_id: nil,
  ...>      output_type: 1,
  ...>      output_data: %{output_guard: <<1::160>>, token: <<0::160>>, amount: 1}
  ...>    }
  iex> ExPlasma.Output.to_rlp(output)
  {:ok, [<<1>>, [<<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1>>, <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>, <<1>>]]}
  """
  @spec to_rlp(output()) :: {:ok, list()} | {:error, :invalid_output_data | :unrecognized_output_type}
  def to_rlp(%__MODULE__{output_type: nil}), do: {:error, :invalid_output_data}

  def to_rlp(output) do
    case get_output_module(output.output_type) do
      {:ok, module} -> {:ok, module.to_rlp(output)}
      {:error, :unrecognized_output_type} = error -> error
    end
  end

  @doc """
  Transforms an Output identifer into an RLP encoded position. This is to generate
  the `inputs` in a Transaction.

  ## Example

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
  iex> ExPlasma.Output.to_rlp_id(output)
  {:ok, <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 59, 154, 202, 0>>}
  """
  @spec to_rlp_id(input_position()) :: {:ok, binary()} | {:error, :invalid_output_id}
  def to_rlp_id(%__MODULE__{output_id: id}) when is_map(id), do: {:ok, Position.to_rlp(id)}
  def to_rlp_id(_), do: {:error, :invalid_output_id}

  @doc """
  Validates the Output

  ## Example

  # Validate a Payment v1 Output

  iex> encoded = <<245, 1, 243, 148, 205, 193, 229, 59, 220, 116, 187, 245, 181, 247, 21, 214,
  ...>  50, 125, 202, 87, 133, 226, 40, 180, 148, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  ...>  0, 0, 0, 0, 0, 0, 0, 0, 136, 13, 224, 182, 179, 167, 100, 0, 0>>
  iex> encoded |> ExPlasma.Output.decode!() |> ExPlasma.Output.validate()
  :ok

  # Validate a Output position

  iex> encoded_position = <<59, 154, 202, 0>>
  iex> encoded_position |> ExPlasma.Output.decode_id!() |> ExPlasma.Output.validate()
  :ok
  """
  @spec validate(t()) :: validation_responses()
  def validate(%__MODULE__{} = output) do
    with :ok <- do_validate_integrity(output),
         :ok <- do_validate_data(output),
         :ok <- do_validate_id(output) do
      :ok
    end
  end

  # Validate that we have either output_type or output_id.
  defp do_validate_integrity(%__MODULE__{output_type: nil, output_id: output_id}) when is_map(output_id), do: :ok
  defp do_validate_integrity(%__MODULE__{output_type: type, output_id: nil}) when is_integer(type), do: :ok
  defp do_validate_integrity(_), do: {:error, {:output, :invalid_output}}

  # Validate the output type and data. Bypass the validation if it doesn't
  # exist in the output body.
  defp do_validate_data(%__MODULE__{output_type: nil}), do: :ok

  defp do_validate_data(output) do
    case get_output_module(output.output_type) do
      {:ok, module} -> module.validate(output)
      {:error, :unrecognized_output_type} -> {:error, {:output_type, :unrecognized_output_type}}
    end
  end

  # Validate the output ID. Bypass the validation if it doesn't
  # exist in the output body.
  defp do_validate_id(output), do: Position.validate(output.output_id)

  defp parse_output_type(output_type_rlp) do
    with {:ok, output_type} <- RlpDecoder.parse_uint256(output_type_rlp),
         {:ok, module} <- get_output_module(output_type) do
      {:ok, module}
    else
      _ -> {:error, :unrecognized_output_type}
    end
  end

  defp get_output_module(type) do
    case Map.get(@output_types_modules, type) do
      nil -> {:error, :unrecognized_output_type}
      module -> {:ok, module}
    end
  end
end
