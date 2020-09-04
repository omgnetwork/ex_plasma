defmodule ExPlasma.SignatureTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias ExPlasma.Crypto
  alias ExPlasma.Signature

  describe "signature_digest/2" do
    test "calculates digest" do
      private_key = "0x8da4ef21b864d2cc526dbdb2a120bd2874c36c9d0a1fb7f8c63d7f7a8b41de8f"
      hash_digest = <<2::256>>

      result = Signature.signature_digest(hash_digest, private_key)

      expected_result =
        <<73, 102, 23, 43, 29, 88, 149, 68, 77, 65, 248, 57, 200, 155, 43, 249, 154, 95, 100, 185, 121, 244, 84, 178,
          159, 90, 254, 45, 27, 177, 221, 218, 21, 214, 167, 20, 61, 86, 189, 86, 241, 39, 239, 70, 71, 66, 201, 140,
          21, 23, 206, 201, 129, 255, 24, 20, 160, 152, 36, 114, 115, 245, 33, 208, 28>>

      assert result == expected_result
    end
  end

  describe "recover_public/3" do
    test "returns an error from an invalid hash" do
      {:error, "Recovery id invalid 0-3"} =
        Signature.recover_public(
          <<2::256>>,
          55,
          38_938_543_279_057_362_855_969_661_240_129_897_219_713_373_336_787_331_739_561_340_553_100_525_404_231,
          23_772_455_091_703_794_797_226_342_343_520_955_590_158_385_983_376_086_035_257_995_824_653_222_457_926
        )
    end

    test "recovers from generating a signed hash 1" do
      data =
        Base.decode16!("ec098504a817c800825208943535353535353535353535353535353535353535880de0b6b3a764000080018080",
          case: :lower
        )

      hash = Crypto.keccak_hash(data)
      v = 27
      r = 18_515_461_264_373_351_373_200_002_665_853_028_612_451_056_578_545_711_640_558_177_340_181_847_433_846
      s = 46_948_507_304_638_947_509_940_763_649_030_358_759_909_902_576_025_900_602_547_168_820_602_576_006_531
      {:ok, public_key} = Signature.recover_public(hash, v, r, s)

      assert public_key ==
               <<75, 194, 163, 18, 101, 21, 63, 7, 231, 14, 11, 171, 8, 114, 78, 107, 133, 226, 23, 248, 205, 98, 140,
                 235, 98, 151, 66, 71, 187, 73, 51, 130, 206, 40, 202, 183, 154, 215, 17, 158, 225, 173, 62, 188, 219,
                 152, 161, 104, 5, 33, 21, 48, 236, 198, 207, 239, 161, 184, 142, 109, 255, 153, 35, 42>>
    end

    test "recovers from generating a signed hash 2" do
      {v, r, s} =
        {37, 18_515_461_264_373_351_373_200_002_665_853_028_612_451_056_578_545_711_640_558_177_340_181_847_433_846,
         46_948_507_304_638_947_509_940_763_649_030_358_759_909_902_576_025_900_602_547_168_820_602_576_006_531}

      data =
        Base.decode16!("ec098504a817c800825208943535353535353535353535353535353535353535880de0b6b3a764000080018080",
          case: :lower
        )

      hash = Crypto.keccak_hash(data)
      {:ok, public_key} = Signature.recover_public(hash, v, r, s, 1)

      assert public_key ==
               <<75, 194, 163, 18, 101, 21, 63, 7, 231, 14, 11, 171, 8, 114, 78, 107, 133, 226, 23, 248, 205, 98, 140,
                 235, 98, 151, 66, 71, 187, 73, 51, 130, 206, 40, 202, 183, 154, 215, 17, 158, 225, 173, 62, 188, 219,
                 152, 161, 104, 5, 33, 21, 48, 236, 198, 207, 239, 161, 184, 142, 109, 255, 153, 35, 42>>
    end
  end
end
