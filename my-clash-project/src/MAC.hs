module MAC where

import Clash.Prelude

-- | Combinational circuit: multiply inputs (x, y) and add accumulator acc
ma :: Num a => a -> (a, a) -> a
ma acc (x, y) = acc + x * y

-- | Mealy state transition function: (current_state, input) -> (next_state, output)
macT :: Num a => a -> (a, a) -> (a, a)
macT acc (x, y) = (acc', o)
  where
    acc' = ma acc (x, y)
    o    = acc

-- | Sequential MAC circuit with initial state 0
mac
  :: (HiddenClockResetEnable dom, Num a, NFDataX a)
  => Signal dom (a, a)
  -> Signal dom a
mac inp = mealy macT 0 inp

-- | Top Entity for VHDL / Verilog / SystemVerilog compilation
-- Uses 9-bit signed integers in System clock domain
topEntity
  :: Clock System
  -> Reset System
  -> Enable System
  -> Signal System (Signed 9, Signed 9)
  -> Signal System (Signed 9)
topEntity = exposeClockResetEnable mac
