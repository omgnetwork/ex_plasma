defmodule ExPlasma do
  @moduledoc """
  Documentation for ExPlasma.
  """

  alias ExPlasma.Block

  @doc """
  Returns the operator address.

  ## Example

    iex> ExPlasma.get_operator()
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

    iex> ExPlasma.get_block(0)
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

    iex> ExPlasma.get_next_child_block()
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

    iex> ExPlasma.get_child_block_interval()
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
  Returns the next deposit block to be mined.

  ## Examples

    iex> ExPlasma.get_next_deposit_block()
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
end
