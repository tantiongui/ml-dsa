module Main where

import qualified SampleInBall as Root (sampleInBall)
import System.IO (hSetEncoding, stdout, utf8)

-- | Test Root SampleInBall against simulated SHAKE256 byte stream
main :: IO ()
main = do
  hSetEncoding stdout utf8
  putStrLn "=== NIST FIPS 204 SampleInBall Specification Test ==="

  let testSigns = [1, -1, 1, 1, -1, -1, 1, 1, 1, -1, 1, -1, 1, 1, -1, 1,
                   1, -1, 1, 1, -1, 1, -1, 1, 1, 1, -1, 1, 1, -1, 1, -1,
                   1, -1, 1, 1, -1, 1, 1] -- 39 signs
      testBytes = [255, 10, 20, 30, 250, 40, 50, 60, 70, 80, 90, 100, 110,
                   120, 130, 140, 150, 160, 170, 180, 190, 200, 210, 215,
                   218, 220, 222, 224, 226, 228, 230, 232, 234, 236, 238,
                   240, 242, 244, 246, 248, 250, 252, 254]
      
      poly = Root.sampleInBall 39 testSigns testBytes
      nonZeros = [(idx, val) | (idx, val) <- zip [0..] poly, val /= 0]

  putStrLn $ "Polynomial Length: " ++ show (length poly)
  putStrLn $ "Non-Zero Count: " ++ show (length nonZeros)
  putStrLn $ "First 10 Non-Zero Coefficients:"
  mapM_ (\(i, v) -> putStrLn $ "  c[" ++ show i ++ "] = " ++ show v) (take 10 nonZeros)

  let isValid = length poly == 256 && length nonZeros == 39 && all (\(_, v) -> abs v == 1) nonZeros
  putStrLn $ "Verdict: " ++ if isValid then "PASSED [OK]" else "FAILED [X]"
