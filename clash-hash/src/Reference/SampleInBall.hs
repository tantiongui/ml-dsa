{-# LANGUAGE DataKinds #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}

-- |
-- Module      : Reference.SampleInBall
-- Description : Pure Haskell Reference Implementation of FIPS 204 SampleInBall (Algorithm 29)
-- License     : MIT
-- Standard    : NIST FIPS 204 (ML-DSA), Algorithm 29
--
-- This module implements the golden specification model for SampleInBall.
-- It generates a polynomial c in R with coefficients from {-1, 0, 1}
-- and Hamming weight tau <= 64 from a 32-byte seed rho using SHAKE256 XOF.
module Reference.SampleInBall
  ( sampleInBall,
    sampleInBallTau,
    sampleInBallBS,
  )
where

import Data.Bits (testBit)
import Data.ByteString (ByteString)
import Data.ByteString qualified as BS
import Data.Int (Int32)
import Data.Word (Word8)
import Reference.Crypton (shake256)
import Prelude

-- | Polynomial representation: List of 256 coefficients in Z_q or {-1, 0, 1}
type Poly = [Int32]

-- | ML-DSA modulus q = 8380417
modQ :: Int32
modQ = 8380417

-- | FIPS 204 Algorithm 29 SampleInBall with configurable tau (e.g., 39, 49, 60).
-- Input: 32-byte seed rho.
-- Output: List of 256 coefficients in Z_q (-1 represented as q - 1 = 8380416).
sampleInBallTau :: Int -> ByteString -> Poly
sampleInBallTau tau rho =
  let -- Step 2-4: Absorb rho into SHAKE256 XOF and squeeze initial byte stream.
      -- 256 bytes is guaranteed to cover max requirement (< 221 bytes by FIPS 204 bound).
      stream = BS.unpack (shake256 256 rho)
      (signBytes, byteStream) = splitAt 8 stream

      -- Step 5: Convert 8 sign bytes into 64 bits h[0..63] (little-endian per byte)
      signBits = [testBit (signBytes !! (k `div` 8)) (k `mod` 8) | k <- [0 .. 63]]

      -- Step 1: Initialize polynomial c to 256 zeros
      initPoly = replicate 256 (0 :: Int32)

      -- Step 6-13: Fisher-Yates shuffle loop for i from (256 - tau) to 255
      go [] _ _ c = c
      go (i : is) bs hIdx c =
        -- Step 7-10: Rejection sampling to extract pseudorandom byte j <= i
        let (j, bs') = findValidByte bs i
            -- Step 12: Determine sign (-1)^h[i + tau - 256]
            signBit = signBits !! hIdx
            signVal = if signBit then modQ - 1 else 1 -- -1 in Z_q is q - 1

            -- Step 11-12: Swap c[i] <- c[j] and set c[j] <- signVal
            cj = c !! j
            c' = updatePoly i j cj signVal c
         in go is bs' (hIdx + 1) c'

      indices = [(256 - tau) .. 255]
   in go indices byteStream 0 initPoly

-- | Helper to find the first byte j <= i in the squeezed byte stream (Rejection Sampling).
findValidByte :: [Word8] -> Int -> (Int, [Word8])
findValidByte [] _ = error "SampleInBall: SHAKE256 squeeze stream unexpectedly exhausted"
findValidByte (b : bs) i =
  let j = fromIntegral b
   in if j <= i
        then (j, bs)
        else findValidByte bs i

-- | Update polynomial coefficients according to Algorithm 29 Lines 11-12.
-- If j < i: c[i] <- old c[j], c[j] <- signVal.
-- If j == i: c[i] <- signVal.
updatePoly :: Int -> Int -> Int32 -> Int32 -> [Int32] -> [Int32]
updatePoly i j cj signVal c
  | j == i = setIndex i signVal c
  | otherwise = setIndex j signVal (setIndex i cj c)

-- | Set list element at specific 0-based index.
setIndex :: Int -> a -> [a] -> [a]
setIndex idx val xs =
  let (left, _ : right) = splitAt idx xs
   in left ++ (val : right)

-- | Default SampleInBall using tau = 39 (ML-DSA-44 default).
sampleInBall :: ByteString -> Poly
sampleInBall = sampleInBallTau 39

-- | ByteString variant returning 256 coefficients as raw bytes for test harness.
sampleInBallBS :: Int -> ByteString -> ByteString
sampleInBallBS tau rho =
  let coeffs = sampleInBallTau tau rho
   in BS.pack (map fromIntegral coeffs)
