defmodule ExPlasma.InFlightExitTest do
  use ExUnit.Case, async: true
  import ExPlasma.Encoding, only: [to_binary: 1]
  alias ExPlasma.InFlightExit

  doctest ExPlasma.InFlightExit

  describe "txbytes_to_id/1" do
    test "basic txbytes is converted to the correct IDs" do
      assert InFlightExit.txbytes_to_id(to_binary("0x")) == 5060277488387867361168243832726934991540486235
      assert InFlightExit.txbytes_to_id(to_binary("0x1234")) == 3817219175777579444019728485725459454579489354
    end
  end
end
