defmodule ExPlasma.InFlightExitTest do
  use ExUnit.Case, async: true
  import ExPlasma.Encoding, only: [to_binary: 1]
  alias ExPlasma.InFlightExit

  doctest ExPlasma.InFlightExit

  describe "txbytes_to_id/1" do
    test "basic txbytes is converted to the correct IDs" do
      # The right hand side of these assertions should match results from this contract:
      #
      # pragma solidity 0.5.11;
      #
      # contract MiniIFE {
      #     uint constant internal ONE = uint(1);
      #
      #     function txbytes_to_id(bytes memory _txBytes) public pure returns(uint160) {
      #         return uint160(setBit(uint256(keccak256(_txBytes)) >> 105, 151));
      #     }
      #
      #     function setBit(uint _self, uint8 _index) internal pure returns (uint) {
      #         return _self | ONE << _index;
      #     }
      # }
      assert InFlightExit.txbytes_to_id(to_binary("0x")) == 5060277488387867361168243832726934991540486235
      assert InFlightExit.txbytes_to_id(to_binary("0x1234")) == 3817219175777579444019728485725459454579489354
      assert InFlightExit.txbytes_to_id(to_binary("0xb26f143eb9e68e5b")) == 4423187252251026420447811542410043191383319711
      assert InFlightExit.txbytes_to_id(to_binary("0x70de28d3cd1cb609")) == 3110272171107387954030746231895833085925917747
      assert InFlightExit.txbytes_to_id(to_binary("0xc235a61a575eb3e2")) == 5361575098523492156916835341228175600149117682
      assert InFlightExit.txbytes_to_id(to_binary("0x8fdeb13e6acdc74955fdcf0f345ae57a")) == 4404745967111218594847696181449381826825993906
      assert InFlightExit.txbytes_to_id(to_binary("0x00000000000000000000000000000000")) == 5581496182896756123499329818246993621247309773
      assert InFlightExit.txbytes_to_id(to_binary("0xffffffffffffffffffffffffffffffff")) == 5148223842797971894055932452183428950371578310
    end
  end
end
