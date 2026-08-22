{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE NoImplicitPrelude #-}

-- |
-- Module      : Component.SampleInBall
-- Description : Hardware implementation of NIST FIPS 204 SampleInBall (Algorithm 29)
-- License     : MIT
-- Standard    : NIST FIPS 204 (ML-DSA), Algorithm 29
module Component.SampleInBall
  ( Input (..),
    Output (..),
    State (..),
    sampleInBallT,
    sampleInBall,
    topEntity,
    goldenSampleInBall,
    simSampleInBall,
    verifySampleInBall,
  )
where

import Clash.Prelude
import qualified Prelude as P

-- | Modulus q for ML-DSA (8380417)
modQ :: Signed 24
modQ = 8380417

-- | Input signals for SampleInBall hardware module
data Input = Input
  { start     :: Bool
  , byteIn    :: Unsigned 8
  , byteValid :: Bool
  , signBitIn :: Bool
  } deriving (Generic, NFDataX, Show, Eq)

-- | Output signals for SampleInBall hardware module
data Output = Output
  { busy      :: Bool
  , done      :: Bool
  , needByte  :: Bool
  , polyOut   :: Vec 256 (Signed 24)
  } deriving (Generic, NFDataX, Show, Eq)

-- | Internal FSM State
data State
  = Idle
  | FetchByte (Index 256) (Vec 256 (Signed 24))
  | Done (Vec 256 (Signed 24))
  deriving (Generic, NFDataX, Show, Eq)

-- | Mealy transition function for SampleInBall (Algorithm 29).
-- Defaults to tau = 39 (ML-DSA-44 standard). Loop index starts at 256 - 39 = 217.
sampleInBallT :: State -> Input -> (State, Output)
sampleInBallT state Input{..} = case state of
  Idle ->
    if start then
      (FetchByte 217 (repeat 0), Output True False True (repeat 0))
    else
      (Idle, Output False False False (repeat 0))

  FetchByte i poly ->
    if byteValid then
      let j = fromIntegral byteIn :: Index 256
      in if j <= i then
        -- Valid byte j <= i: read poly!!j, swap c[i] <- c[j], c[j] <- signVal
        let signVal = if signBitIn then -1 else 1
            cj = poly !! j
            poly' = replace j signVal (replace i cj poly)
        in if i == 255 then
          (Done poly', Output True True False poly')
        else
          (FetchByte (i + 1) poly', Output True False True poly')
      else
        -- Rejected byte j > i: stay in FetchByte and request next byte
        (FetchByte i poly, Output True False True poly)
    else
      -- Waiting for valid byte input
      (FetchByte i poly, Output True False True poly)

  Done poly ->
    if start then
      (FetchByte 217 (repeat 0), Output True False True (repeat 0))
    else
      (Done poly, Output False True False poly)

-- | Sequential SampleInBall circuit with initial state Idle
sampleInBall
  :: HiddenClockResetEnable dom
  => Signal dom Input
  -> Signal dom Output
sampleInBall = mealy sampleInBallT Idle

{-# ANN
  topEntity
  ( Synthesize
      { t_name = "Component_SampleInBall",
        t_inputs =
          [ PortName "CLK",
            PortName "RST",
            PortName "EN",
            PortProduct
              ""
              [ PortName "START",
                PortName "BYTE_IN",
                PortName "BYTE_VALID",
                PortName "SIGN_BIT_IN"
              ]
          ],
        t_output =
          PortProduct
            ""
            [ PortName "BUSY",
              PortName "DONE",
              PortName "NEED_BYTE",
              PortName "POLY_OUT"
            ]
      }
  )
  #-}
{-# NOINLINE topEntity #-}
-- | Top Entity for Verilog / SystemVerilog compilation
topEntity
  :: Clock System
  -> Reset System
  -> Enable System
  -> Signal System Input
  -> Signal System Output
topEntity = exposeClockResetEnable sampleInBall

--------------------------------------------------------------------------------
-- Golden Reference Model & Simulation Test Verification
--------------------------------------------------------------------------------

-- | Pure Haskell Golden Model for SampleInBall (tau = 39)
goldenSampleInBall :: [Bool] -> [Unsigned 8] -> Vec 256 (Signed 24)
goldenSampleInBall signs bytes = go 217 signs bytes (repeat 0)
  where
    go :: Index 256 -> [Bool] -> [Unsigned 8] -> Vec 256 (Signed 24) -> Vec 256 (Signed 24)
    go _ [] _ poly = poly
    go _ _ [] poly = poly
    go i (s:ss) (b:bs) poly
      | j <= i =
          let signVal = if s then -1 else 1
              cj = poly !! j
              poly' = replace j signVal (replace i cj poly)
          in if i == 255 then poly' else go (i + 1) ss bs poly'
      | otherwise = go i (s:ss) bs poly -- Rejection: retry same i and s with next byte
      where j = fromIntegral b

-- | Cycle-by-cycle simulation driver for Clash FSM
simSampleInBall :: [Bool] -> [Unsigned 8] -> Vec 256 (Signed 24)
simSampleInBall signs0 bytes0 = go Idle (Input True 0 False False) signs0 bytes0
  where
    go st inp signs bytes =
      let (st', out) = sampleInBallT st inp
      in if done out then
           polyOut out
         else case st' of
           FetchByte i _ -> case bytes of
             [] -> repeat 0
             (b:bs) ->
               let j = fromIntegral b :: Index 256
               in if j <= i then
                    case signs of
                      (s:ss) -> go st' (Input False b True s) ss bs
                      []     -> go st' (Input False b True False) [] bs
                  else
                    case signs of
                      (s:_) -> go st' (Input False b True s) signs bs
                      []    -> go st' (Input False b True False) [] bs
           _ -> go st' (Input False 0 False False) signs bytes

-- | Verification assertion: True if Clash FSM output matches Golden Model 100%
verifySampleInBall :: Bool
verifySampleInBall =
  let testBytes = P.concat [ [fromIntegral (k `P.mod` (217 + k)), 250] | k <- [0..38 :: Int] ]
      testSigns = [ (k `P.mod` 2) == 0 | k <- [0..38 :: Int] ]
      goldenResult = goldenSampleInBall testSigns testBytes
      fsmResult    = simSampleInBall testSigns testBytes
  in goldenResult == fsmResult
