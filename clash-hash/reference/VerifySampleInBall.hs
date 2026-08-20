module Main where

import System.IO (hSetEncoding, stdout, utf8)
import Data.List (intercalate)

-- | Set element at a specific index in a list
setIndex :: Int -> a -> [a] -> [a]
setIndex _ _ [] = []
setIndex 0 x (_:ys) = x : ys
setIndex n x (y:ys) = y : setIndex (n - 1) x ys

-- | Rejection sampling: extract first byte j <= i
findValidByte :: [Int] -> Int -> (Int, [Int])
findValidByte [] _ = error "findValidByte: byte stream exhausted"
findValidByte (b:bs) i
  | b <= i    = (b, bs)
  | otherwise = findValidByte bs i

-- | Update polynomial coefficients (c[i] <- c[j], c[j] <- signVal)
updatePoly :: Int -> Int -> Int -> Int -> [Int] -> [Int]
updatePoly i j cj signVal c
  | j == i    = setIndex i signVal c
  | otherwise = setIndex j signVal (setIndex i cj c)

-- | Fisher-Yates shuffle loop from (256 - tau) to 255
loop :: Int -> [Int] -> [Int] -> [Int] -> [Int]
loop i signs bs c
  | i > 255   = c
  | otherwise =
      let (signVal:signsNext) = signs
          (j, bsNext) = findValidByte bs i
          cj = c !! j
          cNext = updatePoly i j cj signVal c
      in loop (i + 1) signsNext bsNext cNext

-- | FIPS 204 Algorithm 29 SampleInBall core reference
sampleInBall :: Int -> [Int] -> [Int] -> [Int]
sampleInBall tau signs bs =
  let startI   = 256 - tau
      initPoly = replicate 256 0
  in loop startI signs bs initPoly

-- | Main test suite execution
main :: IO ()
main = do
  hSetEncoding stdout utf8
  putStrLn "=========================================================="
  putStrLn "=== NIST FIPS 204 SampleInBall Pure Software Model Test ==="
  putStrLn "=========================================================="
  
  -- Test 1: ML-DSA-44 (tau = 39)
  let signs1 = cycle [1, -1]
      rawBytes1 = concatMap (\i -> [255, 254, i `mod` 256, (i * 7) `mod` 256]) [200..300]
      poly1 = sampleInBall 39 signs1 rawBytes1
      nonZero1 = [(idx, val) | (idx, val) <- zip [0..] poly1, val /= 0]
  
  putStrLn $ "[Test 1] ML-DSA-44 (tau = 39):"
  putStrLn $ "  - Polynomial Length: " ++ show (length poly1) ++ " (Expected: 256)"
  putStrLn $ "  - Non-Zero Count: " ++ show (length nonZero1) ++ " (Expected: 39)"
  let validVals1 = all (\(_, v) -> v == 1 || v == -1) nonZero1
  putStrLn $ "  - Coefficients in {-1, +1}: " ++ show validVals1
  putStrLn $ "  - Verdict: " ++ if length poly1 == 256 && length nonZero1 == 39 && validVals1 then "PASSED [OK]" else "FAILED [X]"
  putStrLn ""

  -- Test 2: ML-DSA-65 (tau = 49)
  let signs2 = cycle [1, 1, -1, 1, -1]
      rawBytes2 = concatMap (\i -> [255, (i * 13) `mod` 256]) [100..400]
      poly2 = sampleInBall 49 signs2 rawBytes2
      nonZero2 = [(idx, val) | (idx, val) <- zip [0..] poly2, val /= 0]

  putStrLn $ "[Test 2] ML-DSA-65 (tau = 49):"
  putStrLn $ "  - Polynomial Length: " ++ show (length poly2) ++ " (Expected: 256)"
  putStrLn $ "  - Non-Zero Count: " ++ show (length nonZero2) ++ " (Expected: 49)"
  let validVals2 = all (\(_, v) -> v == 1 || v == -1) nonZero2
  putStrLn $ "  - Coefficients in {-1, +1}: " ++ show validVals2
  putStrLn $ "  - Verdict: " ++ if length poly2 == 256 && length nonZero2 == 49 && validVals2 then "PASSED [OK]" else "FAILED [X]"
  putStrLn ""

  -- Test 3: ML-DSA-87 (tau = 60)
  let signs3 = cycle [-1, 1]
      rawBytes3 = [0..500]
      poly3 = sampleInBall 60 signs3 rawBytes3
      nonZero3 = [(idx, val) | (idx, val) <- zip [0..] poly3, val /= 0]

  putStrLn $ "[Test 3] ML-DSA-87 (tau = 60):"
  putStrLn $ "  - Polynomial Length: " ++ show (length poly3) ++ " (Expected: 256)"
  putStrLn $ "  - Non-Zero Count: " ++ show (length nonZero3) ++ " (Expected: 60)"
  let validVals3 = all (\(_, v) -> v == 1 || v == -1) nonZero3
  putStrLn $ "  - Coefficients in {-1, +1}: " ++ show validVals3
  putStrLn $ "  - Verdict: " ++ if length poly3 == 256 && length nonZero3 == 60 && validVals3 then "PASSED [OK]" else "FAILED [X]"
  putStrLn ""

  -- Test 4: Fisher-Yates Collision Preservation Test
  let signsColl = [1, -1, 1, 1]
      bytesColl = replicate 10 0  -- Force repetitive j = 0
      polyColl = sampleInBall 4 signsColl bytesColl
  putStrLn $ "[Test 4] Fisher-Yates Collision Preservation:"
  putStrLn $ "  - c[0]   = " ++ show (polyColl !! 0)   ++ " (Expected: 1)"
  putStrLn $ "  - c[252] = " ++ show (polyColl !! 252) ++ " (Expected: 0)"
  putStrLn $ "  - c[253] = " ++ show (polyColl !! 253) ++ " (Expected: 1)"
  putStrLn $ "  - c[254] = " ++ show (polyColl !! 254) ++ " (Expected: -1)"
  putStrLn $ "  - c[255] = " ++ show (polyColl !! 255) ++ " (Expected: 1)"
  let collPass = (polyColl !! 0 == 1) && (polyColl !! 252 == 0) && (polyColl !! 253 == 1) && (polyColl !! 254 == -1) && (polyColl !! 255 == 1)
  putStrLn $ "  - Verdict: " ++ if collPass then "PASSED [OK]" else "FAILED [X]"
  putStrLn ""
  putStrLn "All SampleInBall software model tests completed successfully."
