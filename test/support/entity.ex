defmodule ExPlasma.Support.TestEntity do
  @moduledoc """
  Stable entities that have a valid private key/address.
  """

  def alice() do
    %{
      addr: <<99, 100, 231, 104, 170, 156, 129, 68, 252, 45, 124, 232, 218, 107, 175, 51, 13, 180, 254, 40>>,
      addr_encoded: "0x6364e768aa9c8144fc2d7ce8da6baf330db4fe28",
      priv:
        <<252, 157, 117, 210, 154, 177, 98, 65, 111, 244, 232, 247, 38, 113, 36, 4, 61, 191, 110, 125, 222, 219, 194,
          221, 199, 251, 100, 63, 160, 194, 126, 126>>,
      priv_encoded: "0xfc9d75d29ab162416ff4e8f7267124043dbf6e7ddedbc2ddc7fb643fa0c27e7e"
    }
  end

  def bob() do
    %{
      addr: <<70, 55, 228, 199, 167, 80, 4, 228, 159, 169, 40, 95, 34, 176, 220, 96, 12, 124, 194, 203>>,
      addr_encoded: "0x4637e4c7a75004e49fa9285f22b0dc600c7cc2cb",
      priv:
        <<165, 205, 127, 128, 156, 32, 196, 83, 131, 79, 62, 37, 89, 67, 34, 193, 223, 11, 15, 242, 218, 143, 99, 111,
          78, 57, 106, 157, 68, 46, 14, 26>>,
      priv_encoded: "0xa5cd7f809c20c453834f3e25594322c1df0b0ff2da8f636f4e396a9d442e0e1a"
    }
  end

  def carol() do
    %{
      addr: <<240, 54, 26, 40, 211, 42, 228, 46, 237, 159, 242, 9, 238, 29, 5, 63, 118, 62, 24, 248>>,
      addr_encoded: "0xf0361a28d32ae42eed9ff209ee1d053f763e18f8",
      priv:
        <<110, 195, 211, 42, 134, 51, 211, 75, 18, 102, 23, 110, 31, 252, 242, 234, 183, 78, 108, 21, 234, 15, 4, 47,
          211, 255, 219, 30, 238, 109, 228, 64>>,
      priv_encoded: "0x6ec3d32a8633d34b1266176e1ffcf2eab74e6c15ea0f042fd3ffdb1eee6de440"
    }
  end
end
