{-# LANGUAGE OverloadedStrings #-}

module Test.Reference.SampleInBall (spec) where

import Data.ByteString qualified as BS
import Reference.SampleInBall (sampleInBall, sampleInBallTau)
import Test.Hspec
import Prelude

spec :: Spec
spec = describe "Reference SampleInBall (Algorithm 29) Tests" $ do
  it "ML-DSA-44 (tau=39) has exactly 39 non-zero coefficients in {-1, 1}" $ do
    let seed = BS.replicate 32 0
        poly = sampleInBall seed
        nonZero = filter (/= 0) poly
    length poly `shouldBe` 256
    length nonZero `shouldBe` 39
    all (\c -> c == 1 || c == 8380416) nonZero `shouldBe` True

  it "ML-DSA-65 (tau=49) has exactly 49 non-zero coefficients in {-1, 1}" $ do
    let seed = BS.replicate 32 0
        poly = sampleInBallTau 49 seed
        nonZero = filter (/= 0) poly
    length poly `shouldBe` 256
    length nonZero `shouldBe` 49
    all (\c -> c == 1 || c == 8380416) nonZero `shouldBe` True

  it "ML-DSA-87 (tau=60) has exactly 60 non-zero coefficients in {-1, 1}" $ do
    let seed = BS.replicate 32 0
        poly = sampleInBallTau 60 seed
        nonZero = filter (/= 0) poly
    length poly `shouldBe` 256
    length nonZero `shouldBe` 60
    all (\c -> c == 1 || c == 8380416) nonZero `shouldBe` True

  it "Matches known Python / FIPS 204 golden vector for seed 0x00..00" $ do
    let seed = BS.replicate 32 0
        poly = sampleInBall seed
    poly !! 5 `shouldBe` 1
    poly !! 17 `shouldBe` 1
    poly !! 18 `shouldBe` 8380416
    poly !! 23 `shouldBe` 1
    poly !! 25 `shouldBe` 8380416

  it "Is deterministic across multiple calls with same seed" $ do
    let seed = "NIST FIPS 204 SampleInBall Seed"
        poly1 = sampleInBall seed
        poly2 = sampleInBall seed
    poly1 `shouldBe` poly2
