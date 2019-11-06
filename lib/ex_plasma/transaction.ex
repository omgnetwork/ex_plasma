defmodule ExPlasma.Transaction do
  @moduledoc """
  The base transaction for now. There's actually a lot of different
  transaction types.

  TODO achiurizo
  fix this pile of poo
  """

  alias __MODULE__
  alias __MODULE__.Input
  alias __MODULE__.Output

  import ExPlasma.Encoding, only: [to_binary: 1]

  @type t :: %__MODULE__{
          inputs: list(Input.t()),
          outputs: list(Output.t()),
          metadata: binary()
        }

  @callback new(map()) :: struct()

  @callback transaction_type() :: non_neg_integer()

  @callback output_type() :: non_neg_integer()

  # @callback decode(binary) :: struct()

  defstruct(inputs: [], outputs: [], metadata: <<0::160>>)

  @doc """
  Generate an RLP-encodable list for the transaction.
  """
  @spec to_list(struct()) :: list()
  def to_list(%module{inputs: inputs, outputs: outputs, metadata: metadata}) do
    ordered_inputs = Enum.map(inputs, &Input.to_list/1)
    ordered_outputs = Enum.map(outputs, fn o -> [module.output_type()] ++ Output.to_list(o) end)
    [module.transaction_type(), ordered_inputs, ordered_outputs, to_binary(metadata)]
  end

  @doc """
  Encodes a transaction into an RLP encodable list.
  """
  def encode(%{inputs: _inputs, outputs: _outputs, metadata: _metadata} = transaction),
    do: transaction |> Transaction.to_list() |> ExRLP.Encode.encode()
end


