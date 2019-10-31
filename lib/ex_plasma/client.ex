defmodule ExPlasma.Client do
  @moduledoc """
  This module provides functions to talk to the
  contract directly.
  """

  alias ExPlasma.Block

  @doc """
  Returns the operator address.

  ## Example

    iex> ExPlasma.Client.get_operator()
    "ffcf8fdee72ac11b5c542428b35eef5769c409f0"
  """
  @spec get_operator() :: String.t() | tuple()
  def get_operator() do
    data = encode_data("operator()", [])

    case Ethereumex.HttpClient.eth_call(%{data: data, to: contract_address()}) do
      {:ok, resp} ->
        resp
        |> decode_response([:address])
        |> List.first()
        |> Base.encode16(case: :lower)

      other ->
        other
    end
  end

  @doc """
  Returns a `ExPlasma.Block` for the given block number.

  ## Example

    iex> ExPlasma.Client.get_block(0)
    %ExPlasma.Block{
      hash: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0>>,
      timestamp: 0
    }
  """
  @spec get_block(non_neg_integer()) :: Block.t()
  def get_block(blknum) do
    data = encode_data("blocks(uint256)", [blknum])

    case Ethereumex.HttpClient.eth_call(%{data: data, to: contract_address()}) do
      {:ok, resp} ->
        [merkle_root_hash, timestamp] = decode_response(resp, [{:bytes, 32}, {:uint, 256}])
        %Block{hash: merkle_root_hash, timestamp: timestamp}

      other ->
        other
    end
  end

  # TODO achiurizo
  # should there be a consolidated method to:
  # * get the block number from this contract call
  # * then call get_block to return the block struct of it?
  #
  @doc """
  Returns the next child block to be mined.

  ## Example

    iex> ExPlasma.Client.get_next_child_block()
    1000
  """
  @spec get_next_child_block() :: non_neg_integer()
  def get_next_child_block() do
    data = encode_data("nextChildBlock()", [])

    case Ethereumex.HttpClient.eth_call(%{data: data, to: contract_address()}) do
      {:ok, resp} -> List.first(decode_response(resp, [{:uint, 256}]))
      other -> other
    end
  end

  @doc """
  Returns the child block interval, which controls the incrementing
  block number for each child block.

  ## Examples

    iex> ExPlasma.Client.get_child_block_interval()
    1000
  """
  @spec get_child_block_interval() :: non_neg_integer()
  def get_child_block_interval() do
    data = encode_data("childBlockInterval()", [])

    case Ethereumex.HttpClient.eth_call(%{data: data, to: contract_address()}) do
      {:ok, resp} -> List.first(decode_response(resp, [{:uint, 256}]))
      other -> other
    end
  end

  @doc """
  Returns the existing standard exit for the given exit id. The exit id is connected
  to a specific UTXO existing in the contract.
  """
  def get_standard_exit(exit_id) do
    types = [:bool, {:uint, 192}, {:bytes, 32}, :address, {:uint, 256}, {:uint, 256}]
    data = encode_data("standardExits(uint160)", [exit_id])

    case Ethereumex.HttpClient.eth_call(%{data: data, to: contract_address()}) do
      {:ok, resp} -> List.first(decode_response(resp, types))
      other -> other
    end
  end

  @doc """
  Returns the next deposit block to be mined.

  ## Examples

    iex> ExPlasma.Client.get_next_deposit_block()
    1
  """
  @spec get_next_deposit_block() :: non_neg_integer()
  def get_next_deposit_block() do
    data = encode_data("nextDepositBlock()", [])

    case Ethereumex.HttpClient.eth_call(%{data: data, to: contract_address()}) do
      {:ok, resp} -> List.first(decode_response(resp, [{:uint, 256}]))
      other -> other
    end
  end

  def deposit(tx_bytes, from, to, value) do
    data = encode_data("deposit(bytes)", [tx_bytes])

    txmap = %{
      from: from,
      to: to,
      data: data,
      gas: "0x" <> Integer.to_string(180_000, 16),
      value: "0x" <> Integer.to_string(value, 16),
    }

    case Ethereumex.HttpClient.eth_send_transaction(txmap) do
      {:ok, receipt_enc} -> {:ok, Encoding.from_hex(receipt_enc)}
      other -> other
    end
  end

  @spec contract_address() :: String.t()
  defp contract_address() do
    Application.get_env(:ex_plasma, :contract_address)
  end

  @spec encode_data(String.t(), list()) :: binary
  defp encode_data(function_signature, data) do
    data = ABI.encode(function_signature, data)
    "0x" <> Base.encode16(data, case: :lower)
  end

  @spec decode_response(binary(), list()) :: list()
  defp decode_response(binary_response, types) do
    binary_response
    |> String.replace_prefix("0x", "")
    |> Base.decode16!(case: :lower)
    |> ABI.TypeDecoder.decode_raw(types)
  end

  @spec to_hex(binary | non_neg_integer) :: binary
  defp to_hex(non_hex)

  defp to_hex(raw) when is_binary(raw), do: "0x" <> Base.encode16(raw, case: :lower)
  defp to_hex(int) when is_integer(int), do: "0x" <> Integer.to_string(int, 16)

  defp encode_all_integer_opts(opts) do
    opts
    |> Enum.filter(fn {_k, v} -> is_integer(v) end)
    |> Enum.into(opts, fn {k, v} -> {k, to_hex(v)} end)
  end
end
