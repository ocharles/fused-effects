{-# LANGUAGE TypeApplications #-}
module Writer.WriterT.Lazy
( tests
) where

import Control.Effect.Writer
import qualified Control.Monad.Trans.Writer.Lazy as WriterT
import Data.Tuple
import Hedgehog.Function
import Hedgehog.Gen
import Hedgehog.Range
import Pure
import Test.Tasty
import Test.Tasty.Hedgehog
import qualified Writer

tests :: TestTree
tests = testGroup "Writer.WriterT.Lazy"
  [ testProperty "tell append" . forall (genAs :. fmap Blind (Writer.gen genAs) :. Nil) $
    \ w m -> tell_append (~=) runWriter w (getBlind m)
  , testProperty "listen eavesdrop" . forall (fmap Blind (Writer.gen genAs) :. Nil) $
    \ m -> listen_eavesdrop (~=) runWriter (getBlind m)
  , testProperty "censor revision" . forall (fn genAs :. fmap Blind (Writer.gen genAs) :. Nil) $
    \ f m -> censor_revision (~=) runWriter (apply f) (getBlind m)
  ] where
  genAs = list (linear 0 10) genA
  runWriter = fmap swap . WriterT.runWriterT @[A]
