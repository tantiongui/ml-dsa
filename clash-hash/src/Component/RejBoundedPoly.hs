{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE NoImplicitPrelude #-}

-- |
-- Module      : Component.RejBoundedPoly
-- Description : Hardware implementation of NIST FIPS 204 RejBoundedPoly (Algorithm 31)
-- License     : MIT
-- Standard    : NIST FIPS 204 (ML-DSA), Algorithm 31 & Appendix C Table 3 (Loop Bounds)
module Component.RejBoundedPoly
  ( Input (..),
    Output (..),
    State (..),
    maxBytesLimit,
    rejBoundedPolyT,
    rejBoundedPoly,
    topEntity,
  )
where

import AXI4Stream (AXI4Stream (..), AXI4Stream64)
import Clash.Prelude
import Component.CoeffFromHalfByte (coeffFromHalfByte)

-- | Maximum allowable limit for XOF output bytes extracted from stream
-- per NIST FIPS 204 Appendix C, Table 3 (bounds failure probability to <= 2^-256).
maxBytesLimit :: Unsigned 10
maxBytesLimit = 481

-- | Input signals for RejBoundedPoly hardware module
data Input = Input
  { start    :: Bool
  , eta      :: Unsigned 3        -- ^ Parameter eta: 2 (ML-DSA-44/87) or 4 (ML-DSA-65)
  , streamIn :: AXI4Stream64      -- ^ Upstream 64-bit stream from SHAKE-256
  } deriving (Generic, NFDataX, Show, Eq)

-- | Output signals for RejBoundedPoly hardware module
data Output = Output
  { busy    :: Bool
  , done    :: Bool
  , err     :: Bool               -- ^ Loop cutoff triggered (byteCount >= 481)
  , tready  :: Bool               -- ^ AXI4-Stream backpressure
  , polyOut :: Vec 256 (Signed 4) -- ^ Sampled polynomial coefficients in [-eta, eta]
  } deriving (Generic, NFDataX, Show, Eq)

-- | Internal FSM State
-- Tracks:
--   1. Idle: Waiting for start signal
--   2. FetchBeat: Waiting for candidate 64-bit beat (8 bytes / 16 nibbles)
--   3. ProcessBeat: Processing buffered 8 bytes, evaluating z0 and z1 per byte
--   4. Done: Sampling completed (j == 256), holding final polynomial output
--   5. Error: Loop bound exceeded (cutoff >= 481 bytes), intermediate state destroyed
data State
  = Idle
  | FetchBeat
      (Index 257)               -- ^ Current sampled coefficient count j (0..256)
      (Vec 256 (Signed 4))      -- ^ Accumulating polynomial
      (Unsigned 10)             -- ^ Consumed byte counter
      (Unsigned 3)              -- ^ Active eta parameter
  | ProcessBeat
      (Index 257)               -- ^ Current coefficient index j
      (Index 8)                 -- ^ Byte index within buffered beat (0..7)
      (BitVector 64)            -- ^ Buffered 64-bit beat data
      (Vec 256 (Signed 4))      -- ^ Accumulating polynomial
      (Unsigned 10)             -- ^ Consumed byte counter
      (Unsigned 3)              -- ^ Active eta parameter
  | Done (Vec 256 (Signed 4))
  | Error
  deriving (Generic, NFDataX, Show, Eq)

-- | Mealy transition function for RejBoundedPoly (Algorithm 31).
rejBoundedPolyT :: State -> Input -> (State, Output)
rejBoundedPolyT state Input{..} = case state of
  Idle ->
    if start then
      (FetchBeat 0 (repeat 0) 0 eta, Output True False False True (repeat 0))
    else
      (Idle, Output False False False False (repeat 0))

  FetchBeat j poly byteCount currentEta ->
    if tvalid streamIn then
      let beatBuf = tdata streamIn
      in (ProcessBeat j 0 beatBuf poly byteCount currentEta, Output True False False False (repeat 0))
    else
      (FetchBeat j poly byteCount currentEta, Output True False False True (repeat 0))

  ProcessBeat j byteIdx beatBuf poly byteCount currentEta ->
    let bytes        = unpack beatBuf :: Vec 8 (Unsigned 8)
        currentByte  = bytes !! byteIdx
        z0           = fromIntegral (currentByte `mod` 16) :: Unsigned 4
        z1           = fromIntegral (currentByte `div` 16) :: Unsigned 4

        mC0          = coeffFromHalfByte z0 currentEta
        mC1          = coeffFromHalfByte z1 currentEta

        (j1, poly1)  = case mC0 of
          Just c0 | j < 256  -> (j + 1, replace (fromIntegral j) c0 poly)
          _                  -> (j, poly)

        (j2, poly2)  = case mC1 of
          Just c1 | j1 < 256 -> (j1 + 1, replace (fromIntegral j1) c1 poly1)
          _                  -> (j1, poly1)

        byteCount'   = byteCount + 1
        limitReached = byteCount' >= maxBytesLimit
    in
      if j2 == 256 then
        (Done poly2, Output False True False False poly2)
      else if limitReached then
        (Error, Output False True True False (repeat 0))
      else if byteIdx == 7 then
        (FetchBeat j2 poly2 byteCount' currentEta, Output True False False True (repeat 0))
      else
        (ProcessBeat j2 (byteIdx + 1) beatBuf poly2 byteCount' currentEta, Output True False False False (repeat 0))

  Done poly ->
    if start then
      (FetchBeat 0 (repeat 0) 0 eta, Output True False False True (repeat 0))
    else
      (Done poly, Output False True False False poly)

  Error ->
    if start then
      (FetchBeat 0 (repeat 0) 0 eta, Output True False False True (repeat 0))
    else
      (Error, Output False True True False (repeat 0))

-- | Sequential RejBoundedPoly circuit with initial state Idle
rejBoundedPoly
  :: (HiddenClockResetEnable dom)
  => Signal dom Input
  -> Signal dom Output
rejBoundedPoly = mealy rejBoundedPolyT Idle

{-# ANN
  topEntity
  ( Synthesize
      { t_name = "Component_RejBoundedPoly",
        t_inputs =
          [ PortName "CLK",
            PortName "RST",
            PortName "EN",
            PortName "IN"
          ],
        t_output = PortName "OUT"
      }
  )
  #-}
{-# NOINLINE topEntity #-}
topEntity
  :: Clock System
  -> Reset System
  -> Enable System
  -> Signal System Input
  -> Signal System Output
topEntity = exposeClockResetEnable rejBoundedPoly
