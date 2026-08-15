import Prelude

import Test.Tasty

import qualified Tests.Example.Project
import qualified Tests.SampleInBallTest

main :: IO ()
main = defaultMain $ testGroup "."
  [ Tests.Example.Project.accumTests
  , Tests.SampleInBallTest.sampleInBallTests
  ]
