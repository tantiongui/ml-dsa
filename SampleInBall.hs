module SampleInBall where

-- Algorithm 15: CoeffFromHalfByte
-- Convert 4-bit byte to coefficient in [-eta, eta]
coeffFromHalfByte :: Int -> Int -> Maybe Int
coeffFromHalfByte b eta
  | eta == 2 && b < 15 = Just (2 - (b `mod` 5))
  | eta == 4 && b < 9  = Just (4 - b)
  | otherwise          = Nothing

-- Set list element at specific 0-based index
setIndex :: Int -> a -> [a] -> [a]
setIndex _ _ [] = []
setIndex 0 x (_:ys) = x : ys
setIndex n x (y:ys) = y : setIndex (n - 1) x ys

-- Rejection sampling: find random byte j <= i
findValidByte :: [Int] -> Int -> (Int, [Int])
findValidByte [] _ = error "findValidByte: random byte stream exhausted"
findValidByte (b:bs) i
  | b <= i    = (b, bs)
  | otherwise = findValidByte bs i

-- Update polynomial coefficients (swap c[i] <- c[j], c[j] <- signVal)
updatePoly :: Int -> Int -> Int -> Int -> [Int] -> [Int]
updatePoly i j cj signVal c
  | j == i    = setIndex i signVal c
  | otherwise = setIndex j signVal (setIndex i cj c)

-- Loop from (256 - tau) to 255
loop :: Int -> [Int] -> [Int] -> [Int] -> [Int]
loop i signs bs c
  | i > 255   = c
  | otherwise =
      let (signVal:signsNext) = signs
          (j, bsNext) = findValidByte bs i
          cj = c !! j
          cNext = updatePoly i j cj signVal c
      in loop (i + 1) signsNext bsNext cNext

-- Algorithm 29: SampleInBall
-- Generate polynomial with tau non-zero (+1/-1) coefficients
sampleInBall :: Int -> [Int] -> [Int] -> [Int]
sampleInBall tau signs bs =
  let startI   = 256 - tau
      initPoly = replicate 256 0
  in loop startI signs bs initPoly


