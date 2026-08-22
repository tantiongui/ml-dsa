{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE NoImplicitPrelude #-}

-- |
-- Module      : Test.SampleInBall
-- Description : Hspec test suite for Clash Component.SampleInBall hardware module
-- License     : MIT
-- Standard    : NIST FIPS 204 (ML-DSA), Algorithm 29
module Test.SampleInBall (spec) where

import Prelude
import qualified Prelude as P
import Test.Hspec
import Clash.Prelude (toList)
import Component.SampleInBall
  ( goldenSampleInBall
  , simSampleInBall
  , verifySampleInBall
  )

spec :: Spec
spec = describe "Hardware Component.SampleInBall (Algorithm 29) Tests" $ do
  it "Baseline verification: Clash FSM matches Golden Model on alternating signs" $ do
    verifySampleInBall `shouldBe` True

  it "Test Vector 1: Interleaved rejection stream (250 > i) matches Golden Model" $ do
    let testBytes = P.concat [ [fromIntegral (k `P.mod` (217 + k)), 250] | k <- [0..38 :: Int] ]
        testSigns = [ (k `P.mod` 2) == 0 | k <- [0..38 :: Int] ]
        golden = goldenSampleInBall testSigns testBytes
        fsmOut = simSampleInBall testSigns testBytes
        nonZero = [ (i, v) | (i, v) <- P.zip [0..255 :: Int] (toList fsmOut), v /= 0 ]
    fsmOut `shouldBe` golden
    P.length (toList fsmOut) `shouldBe` 256
    P.length nonZero `shouldBe` 39
    P.all (\(_, v) -> v == 1 || v == -1) nonZero `shouldBe` True

  it "Test Vector 2: Homogeneous positive (+1) signs match Golden Model" $ do
    let testSigns = P.replicate 39 False
        testBytes = [ fromIntegral ((k * 7 + 13) `P.mod` (217 + k)) | k <- [0..38 :: Int] ]
        golden = goldenSampleInBall testSigns testBytes
        fsmOut = simSampleInBall testSigns testBytes
        nonZero = [ (i, v) | (i, v) <- P.zip [0..255 :: Int] (toList fsmOut), v /= 0 ]
    fsmOut `shouldBe` golden
    P.length nonZero `shouldBe` 39
    P.all (\(_, v) -> v == 1) nonZero `shouldBe` True

  it "Test Vector 3: Homogeneous negative (-1) signs match Golden Model" $ do
    let testSigns = P.replicate 39 True
        testBytes = [ fromIntegral ((k * 11 + 19) `P.mod` (217 + k)) | k <- [0..38 :: Int] ]
        golden = goldenSampleInBall testSigns testBytes
        fsmOut = simSampleInBall testSigns testBytes
        nonZero = [ (i, v) | (i, v) <- P.zip [0..255 :: Int] (toList fsmOut), v /= 0 ]
    fsmOut `shouldBe` golden
    P.length nonZero `shouldBe` 39
    P.all (\(_, v) -> v == -1) nonZero `shouldBe` True

  it "Test Vector 4: High rejection burst stream (90% rejection) matches Golden Model" $ do
    let testSigns = [ (k `P.mod` 3) /= 0 | k <- [0..38 :: Int] ]
        testBytes = P.concat [ [fromIntegral (k `P.mod` (217 + k))] ++ [fromIntegral b | b <- [247..255 :: Int]] | k <- [0..38 :: Int] ]
        golden = goldenSampleInBall testSigns testBytes
        fsmOut = simSampleInBall testSigns testBytes
        nonZero = [ (i, v) | (i, v) <- P.zip [0..255 :: Int] (toList fsmOut), v /= 0 ]
    fsmOut `shouldBe` golden
    P.length nonZero `shouldBe` 39

  it "Test Vector 5: Forced index collisions (0, 1, 2) match Golden Model" $ do
    let testSigns = [ (k `P.mod` 2) == 0 | k <- [0..38 :: Int] ]
        testBytes = [ fromIntegral (k `P.mod` 3) | k <- [0..38 :: Int] ]
        golden = goldenSampleInBall testSigns testBytes
        fsmOut = simSampleInBall testSigns testBytes
        nonZero = [ (i, v) | (i, v) <- P.zip [0..255 :: Int] (toList fsmOut), v /= 0 ]
    fsmOut `shouldBe` golden
    P.length nonZero `shouldBe` 39

  it "Test Vector 6: Diagonal identity permutation (j == i) matches Golden Model" $ do
    let testSigns = [ (k `P.mod` 2) == 0 | k <- [0..38 :: Int] ]
        testBytes = [ fromIntegral (217 + k) | k <- [0..38 :: Int] ]
        golden = goldenSampleInBall testSigns testBytes
        fsmOut = simSampleInBall testSigns testBytes
        nonZero = [ (i, v) | (i, v) <- P.zip [0..255 :: Int] (toList fsmOut), v /= 0 ]
    fsmOut `shouldBe` golden
    P.length nonZero `shouldBe` 39

  it "Stress Test: 30 Pseudo-random input streams match Golden Model 100%" $ do
    let runStreamTest seed =
          let signs = [ ((k * 13 + seed * 37) `P.mod` 2) == 0 | k <- [0..38 :: Int] ]
              bytes = [ fromIntegral ((k * 61 + seed * 101 + k * seed) `P.mod` 256) | k <- [0..255 :: Int] ]
              golden = goldenSampleInBall signs bytes
              fsmOut = simSampleInBall signs bytes
          in golden == fsmOut
    P.all runStreamTest [1..30 :: Int] `shouldBe` True
