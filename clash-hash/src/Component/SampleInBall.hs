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
  )
where

import Clash.Prelude

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
  , polyOut   :: Vec 256 (BitVector 2)
  } deriving (Generic, NFDataX, Show, Eq)

-- | Internal FSM State storing compact 2-bit coefficients (512 bits total)
data State
  = Idle
  | FetchByte (Index 256) (Vec 256 (BitVector 2))
  | Done (Vec 256 (BitVector 2))
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
        -- signBitIn: True -> -1 (2'b11 = 3), False -> +1 (2'b01 = 1)
        let signVal = if signBitIn then 3 else 1 :: BitVector 2
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
