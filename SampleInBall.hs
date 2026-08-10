module SampleInBall where

-- Algorithm 15. coeffFromHalfByte
coeffFromHalfByte :: Int -> Int -> Maybe Int
coeffFromHalfByte eta b
  | eta == 2 && b < 15 = Just (2 - (b `mod` 5))
  | eta == 4 && b < 9  = Just (4 - b)
  | otherwise          = Nothing

-- Algorithm 29. sampleInBall
updateAt :: Int -> a -> [a] -> [a]
updateAt _ _ [] = []
updateAt 0 x (_:ys) = x : ys
updateAt n x (y:ys) = y : updateAt (n - 1) x ys

getValidJ :: Int -> [Int] -> (Int, [Int])
getValidJ _ [] = error "getValidJ: empty list"
getValidJ i (r:rs)
  | r <= i    = (r, rs)
  | otherwise = getValidJ i rs

step :: Int -> Int -> Int -> [Int] -> [Int]
step i j sign c =
  let old_cj = c !! j
      c' = updateAt i old_cj c
  in updateAt j sign c'

loop :: Int -> [Int] -> [Int] -> [Int] -> [Int]
loop i signs rands c
  | i > 255   = c
  | otherwise =
      let (s:sNext) = signs
          (j, randsNext) = getValidJ i rands
          cNext = step i j s c
      in loop (i + 1) sNext randsNext cNext

sampleInBall :: Int -> [Int] -> [Int] -> [Int]
sampleInBall tau signs rands =
  let startI = 256 - tau
      initC  = replicate 256 0
  in loop startI signs rands initC
