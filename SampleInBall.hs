module SampleInBall where

-- Algorithm 15: CoeffFromHalfByte
-- Convert 4-bit byte to coefficient in [-eta, eta]
coeffFromHalfByte :: Int -> Int -> Maybe Int
coeffFromHalfByte b eta
  | eta == 2 && b < 15 = Just (2 - (b `mod` 5))
  | eta == 4 && b < 9  = Just (4 - b)
  | otherwise          = Nothing

-- Update list element at index
updateAt :: Int -> a -> [a] -> [a]
updateAt _ _ [] = []
updateAt 0 x (_:ys) = x : ys
updateAt n x (y:ys) = y : updateAt (n - 1) x ys

-- Rejection sampling: get random j <= i
getValidJ :: Int -> [Int] -> (Int, [Int])
getValidJ _ [] = error "getValidJ: random byte stream exhausted"
getValidJ i (r:rs)
  | r <= i    = (r, rs)
  | otherwise = getValidJ i rs

-- Fisher-Yates swap step
step :: Int -> Int -> Int -> [Int] -> [Int]
step i j s c =
  let c_j = c !! j
      c'  = updateAt i c_j c
  in updateAt j s c'

-- Loop from (256 - tau) to 255
loop :: Int -> [Int] -> [Int] -> [Int] -> [Int]
loop i signs rands c
  | i > 255   = c
  | otherwise =
      let (s:sNext) = signs
          (j, randsNext) = getValidJ i rands
          cNext = step i j s c
      in loop (i + 1) sNext randsNext cNext

-- Algorithm 29: SampleInBall
-- Generate polynomial with tau non-zero (+1/-1) coefficients
sampleInBall :: Int -> [Int] -> [Int] -> [Int]
sampleInBall tau signs rands =
  let startI = 256 - tau
      c0     = replicate 256 0
  in loop startI signs rands c0

