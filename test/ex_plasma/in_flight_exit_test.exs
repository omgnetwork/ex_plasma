defmodule ExPlasma.InFlightExitTest do
  use ExUnit.Case, async: true
  import ExPlasma.Encoding, only: [to_binary!: 1]
  alias ExPlasma.InFlightExit

  doctest ExPlasma.InFlightExit

  describe "tx_bytes_to_id/1" do
    test "basic tx_bytes is converted to the correct IDs" do
      Application.put_env(:ex_plasma, :exit_id_size, 160)
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
      assert InFlightExit.tx_bytes_to_id(to_binary!("0x")) ==
               5_060_277_488_387_867_361_168_243_832_726_934_991_540_486_235

      assert InFlightExit.tx_bytes_to_id(to_binary!("0x1234")) ==
               3_817_219_175_777_579_444_019_728_485_725_459_454_579_489_354

      assert InFlightExit.tx_bytes_to_id(to_binary!("0xb26f143eb9e68e5b")) ==
               4_423_187_252_251_026_420_447_811_542_410_043_191_383_319_711

      assert InFlightExit.tx_bytes_to_id(to_binary!("0x70de28d3cd1cb609")) ==
               3_110_272_171_107_387_954_030_746_231_895_833_085_925_917_747

      assert InFlightExit.tx_bytes_to_id(to_binary!("0xc235a61a575eb3e2")) ==
               5_361_575_098_523_492_156_916_835_341_228_175_600_149_117_682

      assert InFlightExit.tx_bytes_to_id(to_binary!("0x8fdeb13e6acdc74955fdcf0f345ae57a")) ==
               4_404_745_967_111_218_594_847_696_181_449_381_826_825_993_906

      assert InFlightExit.tx_bytes_to_id(to_binary!("0x00000000000000000000000000000000")) ==
               5_581_496_182_896_756_123_499_329_818_246_993_621_247_309_773

      assert InFlightExit.tx_bytes_to_id(to_binary!("0xffffffffffffffffffffffffffffffff")) ==
               5_148_223_842_797_971_894_055_932_452_183_428_950_371_578_310

      Application.put_env(:ex_plasma, :exit_id_size, 160)
    end
  end

  describe "tx_bytes_to_id/1 168 bit size" do
    test "basic tx_bytes is converted to the correct IDs" do
      Application.put_env(:ex_plasma, :exit_id_size, 168)
      # The right hand side of these assertions are collected from this contract, a stripped down version
      # of https://github.com/omgnetwork/plasma-contracts/blob/v2.0.0/plasma_framework/contracts/src/exits/utils/ExitId.sol#L56-L58
      #
      # pragma solidity 0.5.11;
      #
      # contract ExitId {
      #     uint constant internal ONE = uint(1);
      #     uint8 constant private FIRST_BIT_LOCATION = 167;
      #
      #     function getInFlightExitId(bytes memory _txBytes) public pure returns(uint168) {
      #         return uint168((uint256(keccak256(txBytes)) >> (256 - FIRST_BIT_LOCATION)).setBit(FIRST_BIT_LOCATION));
      #     }
      #
      #     function setBit(uint _self, uint8 _index) internal pure returns (uint) {
      #         return _self | ONE << _index;
      #     }
      # }
      assert InFlightExit.tx_bytes_to_id(to_binary!("0x")) ==
               331_630_345_478_987_275_381_522_027_821_592_411_605_597_305_907_685

      assert InFlightExit.tx_bytes_to_id(to_binary!("0x1234")) ==
               250_165_275_903_759_446_443_276_926_040_503_710_815_321_414_348_783

      assert InFlightExit.tx_bytes_to_id(to_binary!("0xb26f143eb9e68e5b")) ==
               289_877_999_763_523_267_490_467_777_243_384_590_590_497_240_631_486

      assert InFlightExit.tx_bytes_to_id(to_binary!("0x70de28d3cd1cb609")) ==
               203_834_797_005_693_776_955_358_985_053_525_317_119_240_945_512_783

      assert InFlightExit.tx_bytes_to_id(to_binary!("0xc235a61a575eb3e2")) ==
               351_376_185_656_835_581_995_701_720_922_729_716_131_372_576_441_573

      assert InFlightExit.tx_bytes_to_id(to_binary!("0x8fdeb13e6acdc74955fdcf0f345ae57a")) ==
               288_669_431_700_600_821_831_938_616_947_466_687_402_868_336_661_515

      assert InFlightExit.tx_bytes_to_id(to_binary!("0x00000000000000000000000000000000")) ==
               365_788_933_842_321_809_309_652_078_968_634_973_962_063_693_346_008

      assert InFlightExit.tx_bytes_to_id(to_binary!("0xffffffffffffffffffffffffffffffff")) ==
               337_393_997_761_607_886_048_849_589_186_293_199_691_551_756_158_617

      Application.put_env(:ex_plasma, :exit_id_size, 160)
    end
  end
end
