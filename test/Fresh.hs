{-# LANGUAGE RankNTypes #-}
module Fresh
( tests
, gen
, test
) where

import qualified Control.Carrier.Fresh.Strict as FreshC
import Control.Effect.Fresh
import Gen
import qualified Hedgehog.Range as R
import qualified Monad
import Test.Tasty
import Test.Tasty.Hedgehog

tests :: TestTree
tests = testGroup "Fresh"
  [ test "FreshC" FreshC.runFresh
  ] where
  test :: Has Fresh sig m => String -> (forall a . Int -> m a -> PureC (Int, a)) -> TestTree
  test name run = testGroup name
    $  Monad.test (m gen) a b c ((,) <$> n <*> pure ()) (uncurry run)
    ++ Fresh.test (m gen) a                             run
  n = Gen.integral (R.linear 0 100)


gen
  :: Has Fresh sig m
  => (forall a . Gen a -> Gen (m a))
  -> Gen a
  -> Gen (m a)
gen _ a = atom "fmap" fmap <*> fn a <*> label "fresh" fresh


test
  :: Has Fresh sig m
  => (forall a . Gen a -> Gen (m a))
  -> Gen a
  -> (forall a . Int -> m a -> PureC (Int, a))
  -> [TestTree]
test m a runFresh =
  [ testProperty "fresh yields unique values" . forall (Gen.integral (R.linear 0 100) :. m a :. Nil) $
    \ n m -> runFresh n (m >> fresh) /== runFresh n (m >> fresh >> fresh)
  ]