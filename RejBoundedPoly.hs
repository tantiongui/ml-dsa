module RejBoundedPoly where

import Data.Word (Word8)
import Data.Maybe (mapMaybe)

coeffFromHalfByte :: Int -> Int -> Maybe Int
coeffFromHalfByte b eta
  | eta == 2 && b < 15 = Just (2 - (b `mod` 5))
  | eta == 4 && b < 9  = Just (4 - b)
  | otherwise          = Nothing

splitByte :: Word8 -> [Int]
splitByte z = [z0, z1]
    where
        zInt  = fromIntegral z

        z0 = zInt `mod` 16
        z1 = zInt `div` 16

rejBoundedPoly :: Int -> [Word8] -> [Int]
rejBoundedPoly eta stream = 
  take 256 $ mapMaybe (\nibble -> coeffFromHalfByte nibble eta) $ concatMap splitByte stream

