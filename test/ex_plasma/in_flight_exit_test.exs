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
               5_060_277_488_387_867_361_168_243_832_726_934_991_540_486_235

      assert InFlightExit.txbytes_to_id(to_binary("0x1234")) ==
               3_817_219_175_777_579_444_019_728_485_725_459_454_579_489_354

      assert InFlightExit.txbytes_to_id(to_binary("0xb26f143eb9e68e5b")) ==
               4_423_187_252_251_026_420_447_811_542_410_043_191_383_319_711

      assert InFlightExit.txbytes_to_id(to_binary("0x70de28d3cd1cb609")) ==
               3_110_272_171_107_387_954_030_746_231_895_833_085_925_917_747

      assert InFlightExit.txbytes_to_id(to_binary("0xc235a61a575eb3e2")) ==
               5_361_575_098_523_492_156_916_835_341_228_175_600_149_117_682

      assert InFlightExit.txbytes_to_id(to_binary("0x8fdeb13e6acdc74955fdcf0f345ae57a")) ==
               4_404_745_967_111_218_594_847_696_181_449_381_826_825_993_906

      assert InFlightExit.txbytes_to_id(to_binary("0x00000000000000000000000000000000")) ==
               5_581_496_182_896_756_123_499_329_818_246_993_621_247_309_773

      assert InFlightExit.txbytes_to_id(to_binary("0xffffffffffffffffffffffffffffffff")) ==
               5_148_223_842_797_971_894_055_932_452_183_428_950_371_578_310
    end
  end
end
