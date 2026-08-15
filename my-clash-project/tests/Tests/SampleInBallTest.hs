{-# LANGUAGE DataKinds #-}
{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE TemplateHaskell #-}

module Tests.SampleInBallTest where

import Prelude

import Test.Tasty
import Test.Tasty.TH
import Test.Tasty.Hedgehog
import qualified Hedgehog as H

import SampleInBall (verifySampleInBall)

-- | Tasty test verifying Clash FSM matches Golden Reference Model
prop_sampleInBall_golden_match :: H.Property
prop_sampleInBall_golden_match = H.property $ do
  H.assert verifySampleInBall

sampleInBallTests :: TestTree
sampleInBallTests = $(testGroupGenerator)

main :: IO ()
main = defaultMain sampleInBallTests
