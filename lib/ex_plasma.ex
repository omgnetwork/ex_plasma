defmodule ExPlasma do
  @moduledoc """
  Documentation for ExPlasma.
  """

  alias ExPlasma.Transaction
  alias ExPlasma.Utxo

  @doc """

  Produces a RLP encoded transaction bytes for the given transaction data.

  ## Examples

      # Encode a transaction
      iex> {:ok, txn} = ExPlasma.Transaction.Payment.new(%{inputs: [], outputs: []})
      iex> ExPlasma.encode(txn)
      <<229, 1, 192, 192, 128, 160, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>

      # Encode a transaction rlp
      iex> rlp = [1, [], [], 0, <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>]
      iex> ExPlasma.encode(rlp)
      <<217, 128, 192, 192, 128, 148, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0>>

       Encode a signed transaction
      iex> {:ok, txn} = ExPlasma.Transaction.Payment.new(%{inputs: [], outputs: [], sigs: []})
      iex> ExPlasma.encode(txn)
      <<229, 1, 192, 192, 128, 160, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>
  """
  @spec encode(Transaction.t() | Transaction.rlp()) :: <<_::632>>
  def encode(txn) when is_map(txn), do: Transaction.encode(txn)

  def encode(txn) when is_list(txn) do
    with {:ok, transaction} <- Transaction.new(txn), do: Transaction.encode(transaction)
  end

  @doc """

  ## Examples

      # Decodes an encoded transaction bytes
      iex> tx_bytes = <<229, 1, 192, 192, 128, 160, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>
      iex> ExPlasma.decode(tx_bytes)
      {:ok, %ExPlasma.Transaction{
          inputs: [],
          metadata: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
          outputs: [],
          sigs: [],
          tx_data: "",
          tx_type: 1
        }
      }

      # Decodes a signed encoded transaction bytes
      iex> tx_bytes = <<239, 201, 136, 48, 120, 49, 50, 51, 52, 53, 54, 1, 192, 192, 128, 160, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>
      iex> ExPlasma.decode(tx_bytes)
      {:ok, %ExPlasma.Transaction{
        inputs: [],
        metadata: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
          0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
        outputs: [],
        sigs: ["0x123456"],
        tx_data: "",
        tx_type: <<1>>
      }}

       Decodes a transaction rlp data
      iex> rlp = [1, [], [], 0, <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>]
      iex> ExPlasma.decode(rlp)
      {:ok, %ExPlasma.Transaction{
          inputs: [],
          metadata: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
          outputs: [],
          sigs: [],
          tx_data: 0,
          tx_type: 1
      }}

      # Decodes a utxo position
      iex> ExPlasma.decode(1000000000)
      {:ok,
       %ExPlasma.Utxo{
         amount: nil,
         blknum: 1,
         currency: nil,
         oindex: 0,
         output_type: 1,
         owner: nil,
         txindex: 0
       }}

      # Decodes an output utxo rlp data
      iex> rlp = [<<1>>, [<<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1>>, <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>, <<1>>]]
      iex> ExPlasma.decode(rlp)
      {:ok, %ExPlasma.Utxo{
         amount: 1,
         blknum: nil,
         currency: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
         oindex: nil,
         output_type: 1,
         owner: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1>>,
         txindex: nil
       }}
  """
  @spec decode(Transaction.rlp() | Utxo.output_rlp() | Utxo.input_rlp()) ::
          {:ok, Transaction.t()} | {:ok, Utxo.t()} | Utxo.validation_tuples()
  def decode([_output_type, [_owner, _currency, _amount]] = output_rlp), do: Utxo.new(output_rlp)

  def decode([_tx_type, _inputs, _outputs, _tx_data, _metadata] = tx_rlp),
    do: Transaction.new(tx_rlp)

  def decode([_sigs, _tx_type, _inputs, _outputs, _tx_data, _metadata] = tx_rlp),
    do: Transaction.new(tx_rlp)

  def decode(utxo_pos) when is_integer(utxo_pos), do: Utxo.new(utxo_pos)
  def decode(tx_bytes) when is_binary(tx_bytes), do: Transaction.decode(tx_bytes)

  @doc """

  ## Examples

      # Hash a transaction
      iex> {:ok, txn} = ExPlasma.Transaction.Payment.new(%{inputs: [], outputs: []})
      iex> ExPlasma.hash(txn)
      <<3, 225, 217, 46, 83, 133, 97, 248, 114, 1, 89, 94, 179, 68, 60,
        39, 111, 80, 235, 153, 10, 175, 113, 195, 91, 188, 174, 39, 167,
        20, 14, 81>>

      # Hash an encoded transaction bytes
      iex> tx_bytes = <<229, 1, 192, 192, 128, 160, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>
      iex> ExPlasma.hash(tx_bytes)
      <<3, 225, 217, 46, 83, 133, 97, 248, 114, 1, 89, 94, 179, 68, 60,
        39, 111, 80, 235, 153, 10, 175, 113, 195, 91, 188, 174, 39, 167,
        20, 14, 81>>
  """
  @spec hash(Transaction.t() | binary()) :: <<_::256>>
  def hash(txn) when is_map(txn), do: Transaction.hash(txn)
  def hash(txn) when is_binary(txn), do: Transaction.hash(txn)
end
