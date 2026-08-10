module SampleInBall where

-- ============================================================================
-- NIST FIPS 204 (ML-DSA) Reference Algorithms
-- ============================================================================

-- | Algorithm 15: CoeffFromHalfByte(b, eta)
-- Standard Spec: FIPS 204, Section 6.2, Algorithm 15
-- Converts a 4-bit half-byte b into a polynomial coefficient in [-eta, eta].
coeffFromHalfByte :: Int -> Int -> Maybe Int
coeffFromHalfByte b eta
  | eta == 2 && b < 15 = Just (2 - (b `mod` 5))
  | eta == 4 && b < 9  = Just (4 - b)
  | otherwise          = Nothing

-- | Helper function to update an element at a given 0-based index in a list.
updateAt :: Int -> a -> [a] -> [a]
updateAt _ _ [] = []
updateAt 0 x (_:ys) = x : ys
updateAt n x (y:ys) = y : updateAt (n - 1) x ys

-- | Algorithm 29 (Lines 7-10): Rejection sampling to extract valid j <= i
getValidJ :: Int -> [Int] -> (Int, [Int])
getValidJ _ [] = error "getValidJ: random byte stream exhausted"
getValidJ i (r:rs)
  | r <= i    = (r, rs)
  | otherwise = getValidJ i rs

-- | Algorithm 29 (Lines 11-12): Fisher-Yates swap step
--   c[i] <- c[j], c[j] <- (-1)^s
step :: Int -> Int -> Int -> [Int] -> [Int]
step i j s c =
  let c_j = c !! j
      c'  = updateAt i c_j c
  in updateAt j s c'

-- | Algorithm 29 (Lines 6-13): Main loop from i = (256 - tau) to 255
loop :: Int -> [Int] -> [Int] -> [Int] -> [Int]
loop i signs rands c
  | i > 255   = c
  | otherwise =
      let (s:sNext) = signs
          (j, randsNext) = getValidJ i rands
          cNext = step i j s c
      in loop (i + 1) sNext randsNext cNext

-- | Algorithm 29: SampleInBall(rho)
-- Standard Spec: FIPS 204, Algorithm 29
-- Generates a polynomial c in R with tau non-zero coefficients (+1 or -1).
sampleInBall :: Int -> [Int] -> [Int] -> [Int]
sampleInBall tau signs rands =
  let startI = 256 - tau
      c0     = replicate 256 0  -- Line 1: c = (0, 0, ..., 0)
  in loop startI signs rands c0
