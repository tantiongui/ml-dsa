{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE NoImplicitPrelude #-}

module Main where

import Clash.Prelude
import Component.SampleInBall
import AXI4Stream (AXI4Stream (..))
import qualified Prelude as P

-- Run mealy machine with a list of inputs
runSim :: [Input] -> [(State, Output)]
runSim inputs = P.scanl step (Idle, Output False False False False (repeat 0)) inputs
  where
    step (st, _) inp = sampleInBallT st inp

main :: P.IO ()
main = do
  P.putStrLn "============================================================"
  P.putStrLn "Testing Component.SampleInBall FSM & Cutoff (FIPS 204 App C)"
  P.putStrLn "============================================================"

  -- Test 1: Cutoff Test with degenerate stream (all 0xFF bytes, all rejected)
  -- Signs beat: 8 bytes
  -- Candidate beats: all 0xFFFFFFFFFFFFFFFF
  let startInp = Input True (AXI4Stream 0 False False)
      signBeat = Input False (AXI4Stream 0x0123456789ABCDEF True False)
      rejBeat  = Input False (AXI4Stream 0xFFFFFFFFFFFFFFFF True False)
      -- Generate enough beats to exceed 221 bytes:
      -- 8 bytes signs + 28 beats * 8 bytes = 232 bytes
      inputs = [startInp, signBeat] P.++ P.replicate 300 rejBeat
      history = runSim inputs
      
      -- Find first step where done is True
      doneSteps = P.filter (\(_, out) -> done out) history
      
  case doneSteps of
    [] -> P.putStrLn "FAIL: Module never reached done/error!"
    ((st, out) : _) -> do
      P.putStrLn $ "Cutoff reached!"
      P.putStrLn $ "State: " P.++ P.show st
      P.putStrLn $ "Output busy: " P.++ P.show (busy out)
      P.putStrLn $ "Output done: " P.++ P.show (done out)
      P.putStrLn $ "Output err:  " P.++ P.show (err out)
      P.putStrLn $ "Output tready: " P.++ P.show (tready out)
      let nonZeroCoeffs = P.filter (/= 0) (toList (polyOut out))
      P.putStrLn $ "Non-zero coeffs count (should be 0 due to zeroization): " P.++ P.show (P.length nonZeroCoeffs)
      if err out P.&& P.null nonZeroCoeffs P.&& st P.== Error
        then P.putStrLn ">>> TEST 1 (Cutoff & Security Zeroization): PASSED <<<"
        else P.putStrLn ">>> TEST 1: FAILED <<<"

  -- Test 2: Valid Sampling Test (all candidate bytes 0x00, which are always <= i)
  -- 8 bytes signs
  -- Candidate beats: all 0x00
  -- Should accept 39 coefficients in 39 bytes (+ 8 signs = 47 bytes)
  let validBeat = Input False (AXI4Stream 0x0000000000000000 True False)
      validInputs = [startInp, signBeat] P.++ P.replicate 50 validBeat
      validHistory = runSim validInputs
      validDoneSteps = P.filter (\(_, out) -> done out) validHistory

  case validDoneSteps of
    [] -> P.putStrLn "FAIL: Valid stream never reached done!"
    ((stValid, outValid) : _) -> do
      P.putStrLn "\nValid sampling completed!"
      P.putStrLn $ "Output done: " P.++ P.show (done outValid)
      P.putStrLn $ "Output err:  " P.++ P.show (err outValid)
      let nonZero = P.filter (/= 0) (toList (polyOut outValid))
      P.putStrLn $ "Non-zero coeffs count (tau): " P.++ P.show (P.length nonZero)
      if (not (err outValid)) P.&& (P.length nonZero P.== 39)
        then P.putStrLn ">>> TEST 2 (Valid Stream Tau=39 Sampling): PASSED <<<"
        else P.putStrLn ">>> TEST 2: FAILED <<<"

  P.putStrLn "============================================================"
