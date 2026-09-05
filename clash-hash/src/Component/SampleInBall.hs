{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE NoImplicitPrelude #-}

-- |
-- Module      : Component.SampleInBall
-- Description : Hardware implementation of NIST FIPS 204 SampleInBall (Algorithm 29)
-- License     : MIT
-- Standard    : NIST FIPS 204 (ML-DSA), Algorithm 29 & Appendix C (Loop Bounds)
module Component.SampleInBall
  ( Input (..),
    Output (..),
    State (..),
    maxBytesLimit,
    sampleInBallT,
    sampleInBall,
    topEntity,
  )
where

import AXI4Stream (AXI4Stream (..), AXI4Stream64)
import Clash.Prelude

-- | Maximum allowable limit for XOF output bytes extracted from stream
-- per NIST FIPS 204 Appendix C, Table 3 (bounds failure probability to <= 2^-256).
maxBytesLimit :: Index 256
maxBytesLimit = 221

-- | Input signals for SampleInBall hardware module (connected to upstream SHAKE256 stream)
data Input = Input
  { start    :: Bool
  , streamIn :: AXI4Stream64
  } deriving (Generic, NFDataX, Show, Eq)

-- | Output signals for SampleInBall hardware module
data Output = Output
  { busy    :: Bool
  , done    :: Bool
  , err     :: Bool
  , tready  :: Bool
  , polyOut :: Vec 256 (BitVector 2)
  } deriving (Generic, NFDataX, Show, Eq)

-- | Internal FSM State
-- Tracks:
--   1. Idle: Waiting for start signal
--   2. WaitSigns: Waiting for 1st 64-bit beat containing sign bits (8 bytes)
--   3. FetchBeat: Waiting for candidate 64-bit beat (8 candidate bytes)
--   4. ProcessByte: Processing the 8 bytes loaded in buffer, tracking byte count
--   5. Done: Sampling completed, holding final polynomial output
--   6. Error: Loop bound exceeded (cutoff >= 221 bytes), intermediate state destroyed
data State
  = Idle
  | WaitSigns
  | FetchBeat (Index 256) (BitVector 64) (Vec 256 (BitVector 2)) (Index 256)
  | ProcessByte (Index 256) (BitVector 64) (Index 8) (BitVector 64) (Vec 256 (BitVector 2)) (Index 256)
  | Done (Vec 256 (BitVector 2))
  | Error
  deriving (Generic, NFDataX, Show, Eq)

-- | Mealy transition function for SampleInBall (Algorithm 29).
-- Defaults to tau = 39 (ML-DSA-44 standard). Loop index starts at 256 - 39 = 217.
sampleInBallT :: State -> Input -> (State, Output)
sampleInBallT state Input{..} = case state of
  Idle ->
    if start then
      (WaitSigns, Output True False False True (repeat 0))
    else
      (Idle, Output False False False False (repeat 0))

  WaitSigns ->
    if tvalid streamIn then
      let signReg = tdata streamIn
      -- 8 bytes consumed for signs
      in (FetchBeat 217 signReg (repeat 0) 8, Output True False False True (repeat 0))
    else
      (WaitSigns, Output True False False True (repeat 0))

  FetchBeat i signReg poly byteCount ->
    if tvalid streamIn then
      let byteBuf = tdata streamIn
      in (ProcessByte i signReg 0 byteBuf poly byteCount, Output True False False False (repeat 0))
    else
      (FetchBeat i signReg poly byteCount, Output True False False True (repeat 0))

  ProcessByte i signReg byteIdx byteBuf poly byteCount ->
    let bytes        = unpack byteBuf :: Vec 8 (Unsigned 8)
        signs        = unpack signReg :: Vec 64 Bool
        j            = fromIntegral (bytes !! byteIdx) :: Index 256
        signBit      = signs !! (i - 217)
        signVal      = if signBit then 3 else 1 :: BitVector 2
        byteCount'   = byteCount + 1
        limitReached = byteCount' >= maxBytesLimit
    in if j <= i then
      let cj    = poly !! j
          poly' = replace j signVal (replace i cj poly)
      in if i == 255 then
        -- Successfully completed sampling of tau non-zero coefficients
        (Done poly', Output False True False False poly')
      else if limitReached then
        -- Cutoff reached before completing tau coefficients:
        -- FIPS 204 Appendix C: Stop execution, return error, destroy intermediate results.
        (Error, Output False True True False (repeat 0))
      else if byteIdx == 7 then
        (FetchBeat (i + 1) signReg poly' byteCount', Output True False False True (repeat 0))
      else
        (ProcessByte (i + 1) signReg (byteIdx + 1) byteBuf poly' byteCount', Output True False False False (repeat 0))
    else
      -- Candidate byte rejected (j > i)
      if limitReached then
        -- Cutoff reached during rejection:
        -- FIPS 204 Appendix C: Stop execution, return error, destroy intermediate results.
        (Error, Output False True True False (repeat 0))
      else if byteIdx == 7 then
        (FetchBeat i signReg poly byteCount', Output True False False True (repeat 0))
      else
        (ProcessByte i signReg (byteIdx + 1) byteBuf poly byteCount', Output True False False False (repeat 0))

  Done poly ->
    if start then
      (WaitSigns, Output True False False True (repeat 0))
    else
      (Done poly, Output False True False False poly)

  Error ->
    if start then
      (WaitSigns, Output True False False True (repeat 0))
    else
      (Error, Output False True True False (repeat 0))

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
                PortProduct
                  "STREAM_IN"
                  [ PortName "TDATA",
                    PortName "TVALID",
                    PortName "TLAST"
                  ]
              ]
          ],
        t_output =
          PortProduct
            ""
            [ PortName "BUSY",
              PortName "DONE",
              PortName "ERR",
              PortName "TREADY",
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
