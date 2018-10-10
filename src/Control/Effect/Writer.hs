{-# LANGUAGE DeriveFunctor, FlexibleContexts, FlexibleInstances, MultiParamTypeClasses, PolyKinds, TypeOperators, UndecidableInstances #-}
module Control.Effect.Writer where

import Control.Effect
import Data.Bifunctor (first)

data Writer w m k = Tell w k
  deriving (Functor)

instance Effect (Writer w) where
  hfmap _ (Tell w k) = Tell w k

  handle state handler (Tell w k) = Tell w (handler (k <$ state))

tell :: (Subset (Writer w) sig, TermMonad m sig) => w -> m ()
tell w = send (Tell w (pure ()))


runWriter :: (TermMonad m sig, Monoid w) => Eff (WriterH w m) a -> m (w, a)
runWriter m = runWriterH (runEff var m)

newtype WriterH w m a = WriterH { runWriterH :: m (w, a) }

instance (Monoid w, TermMonad m sig) => TermAlgebra (WriterH w m) (Writer w :+: sig) where
  var a = WriterH (pure (mempty, a))
  con = alg \/ (WriterH . con . handle (mempty, ()) (uncurry runWriter'))
    where alg (Tell w k) = WriterH (first (w <>) <$> runWriterH k)
          runWriter' w = fmap (first (w <>)) . runWriterH
