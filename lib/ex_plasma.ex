defmodule ExPlasma do
  @moduledoc """
  Documentation for ExPlasma.
  """

  alias ExPlasma.Block

  @doc """
  Returns a `ExPlasma.Block` for the given block number.
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

  @doc """
  Returns the next child block to be mined.
  """
  @spec get_next_child_block() :: non_neg_integer()
  def get_next_child_block() do
    data = encode_data("nextChildBlock()", [])
    case Ethereumex.HttpClient.eth_call(%{data: data, to: contract_address}) do
      {:ok, resp} -> List.first(decode_response(resp, [{:uint, 256}]))
      other -> other
    end
  end

  @doc """
  Returns the contract address.
  """
  defp contract_address() do
    Application.get_env(:ex_plasma, :contract_address)
  end

  @doc """
  Encodes the function signature and data to be sent to
  the contract.
  """
  @spec encode_data(String.t(), list()) :: binary
  defp encode_data(function_signature, data) do
    data = ABI.encode(function_signature, data)
    "0x" <> Base.encode16(data, case: :lower)
  end

  @doc """
  Decodes the binary response from the contract.
  """
  @spec decode_response(binary(), list(tuple)) :: list()
  defp decode_response(binary_response, types) do
    binary_response
    |> String.replace_prefix("0x", "")
    |> Base.decode16!(case: :lower)
    |> ABI.TypeDecoder.decode_raw(types)
  end
end
