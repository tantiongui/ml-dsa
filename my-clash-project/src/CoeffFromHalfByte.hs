module CoeffFromHalfByte where

import Clash.Prelude

-- | Algorithm 15: CoeffFromHalfByte (NIST FIPS 204 ML-DSA)
-- Converts a 4-bit nibble `b` to a coefficient in range [-eta, eta].
-- Supports eta = 2 (ML-DSA-44 / 87) and eta = 4 (ML-DSA-65).
-- Returns `Nothing` if the half-byte is invalid (rejection sampling).
coeffFromHalfByte :: Unsigned 4 -> Unsigned 3 -> Maybe (Signed 4)
coeffFromHalfByte b eta
  | eta == 2 && b < 15 = Just (2 - fromIntegral (b `mod` 5))
  | eta == 4 && b < 9  = Just (4 - fromIntegral b)
  | otherwise          = Nothing

-- | Top Entity for Verilog / SystemVerilog Synthesis
topEntity
  :: Unsigned 4
  -> Unsigned 3
  -> Maybe (Signed 4)
topEntity b eta = coeffFromHalfByte b eta
