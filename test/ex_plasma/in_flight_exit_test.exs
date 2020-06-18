defmodule ExPlasma.InFlightExitTest do
  use ExUnit.Case, async: true
  import ExPlasma.Encoding, only: [to_binary: 1]
  alias ExPlasma.InFlightExit

  doctest ExPlasma.InFlightExit

  describe "txbytes_to_id/1" do
    test "basic txbytes is converted to the correct IDs" do
      # The right hand side of these assertions are collected from this contract, a stripped down version
      # of https://github.com/omisego/plasma-contracts/blob/v1.0.3/plasma_framework/contracts/src/exits/utils/ExitId.sol#L53-L55
      #
      # pragma solidity 0.5.11;
      #
      # contract ExitId {
      #     uint constant internal ONE = uint(1);
      #
      #     function getInFlightExitId(bytes memory _txBytes) public pure returns(uint160) {
      #         return uint160((uint256(keccak256(_txBytes)) >> 105).setBit(151));
      #     }
      #
      #     function setBit(uint _self, uint8 _index) internal pure returns (uint) {
      #         return _self | ONE << _index;
      #     }
      # }
      assert InFlightExit.txbytes_to_id(to_binary("0x")) ==
               331_630_345_478_987_275_381_522_027_821_592_411_605_597_305_907_685

      assert InFlightExit.txbytes_to_id(to_binary("0x1234")) ==
               250_165_275_903_759_446_443_276_926_040_503_710_815_321_414_348_783

      assert InFlightExit.txbytes_to_id(to_binary("0xb26f143eb9e68e5b")) ==
               289_877_999_763_523_267_490_467_777_243_384_590_590_497_240_631_486

      assert InFlightExit.txbytes_to_id(to_binary("0x70de28d3cd1cb609")) ==
               203_834_797_005_693_776_955_358_985_053_525_317_119_240_945_512_783

      assert InFlightExit.txbytes_to_id(to_binary("0xc235a61a575eb3e2")) ==
               351_376_185_656_835_581_995_701_720_922_729_716_131_372_576_441_573

      assert InFlightExit.txbytes_to_id(to_binary("0x8fdeb13e6acdc74955fdcf0f345ae57a")) ==
               288_669_431_700_600_821_831_938_616_947_466_687_402_868_336_661_515

      assert InFlightExit.txbytes_to_id(to_binary("0x00000000000000000000000000000000")) ==
               365_788_933_842_321_809_309_652_078_968_634_973_962_063_693_346_008

      assert InFlightExit.txbytes_to_id(to_binary("0xffffffffffffffffffffffffffffffff")) ==
               337_393_997_761_607_886_048_849_589_186_293_199_691_551_756_158_617
    end
  end
end
