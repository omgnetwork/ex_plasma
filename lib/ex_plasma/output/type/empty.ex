defmodule ExPlasma.Output.Type.Empty do
  @moduledoc """
  An empty invalid output type. Used to return a default
  response if given an invalid output key.
  """

  @behaviour ExPlasma.Output
  alias ExPlasma.Output

  @impl Output
  @spec to_rlp(any()) :: [<<_::8>> | [], ...]
  def to_rlp(_), do: [<<0>>, []]

  @impl Output
  @spec to_map(any()) :: %{output_type: 0, output_data: []}
  def to_map(_), do: %{output_type: 0, output_data: []}

  @impl Output
  @spec validate(any) :: {:error, {:output_type, :unknown}}
    def validate(_), do: {:error, {:output_type, :unknown}}
end
