{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeApplications #-}

-- |
-- Module      : Test.Reference.SampleInBall
-- Description : Pure Haskell software reference model for NIST FIPS 204 Algorithm 29 (SampleInBall)
-- License     : MIT
module Test.Reference.SampleInBall
  ( run,
  )
where

import Clash.Prelude
import Data.Word (Word8)

-- | Pure software reference model for NIST FIPS 204 Algorithm 29 (SampleInBall).
-- Given a 64-bit sign register and an unbounded stream of candidate rejection bytes,
-- performs Fisher-Yates shuffle to generate a 256-coefficient polynomial with tau=39 non-zero coefficients.
run :: BitVector 64 -> [Word8] -> Vec 256 (BitVector 2)
run signReg candBytes = loop 217 (repeat 0) candBytes
  where
    signBytes :: Vec 8 (Unsigned 8)
    signBytes = unpack signReg

    loop :: Index 256 -> Vec 256 (BitVector 2) -> [Word8] -> Vec 256 (BitVector 2)
    loop _ poly [] = poly
    loop i poly (b : bs)
      | j <= i =
          let k = fromIntegral (i - 217) :: Int
              signByte = signBytes !! (fromIntegral (k `div` 8) :: Index 8)
              signBit = testBit signByte (k `mod` 8)
              signVal = if signBit then 3 else 1 :: BitVector 2
              cj = poly !! j
              poly' = replace j signVal (replace i cj poly)
           in if i == 255
                then poly'
                else loop (i + 1) poly' bs
      | otherwise = loop i poly bs
      where
        j = fromIntegral b :: Index 256
