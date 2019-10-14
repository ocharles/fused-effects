{-# LANGUAGE DeriveFunctor, ExistentialQuantification, FlexibleContexts, StandaloneDeriving #-}

{- | An effect modelling catchable failure when used with 'Control.Effect.Throw.Throw'.

Predefined carriers:

* "Control.Carrier.Error.Either" (with 'Control.Effect.Throw.Throw')
-}
module Control.Effect.Catch
( -- * Catch effect
  Catch(..)
, catchError
  -- * Properties
, catchError_interception
  -- * Re-exports
, Carrier
, Has
, run
) where

import Control.Carrier
import Control.Effect.Throw

-- | 'Catch' effects can be used alongside 'Control.Effect.Throw.Throw' to provide recoverable exceptions.
data Catch e m k
  = forall b . Catch (m b) (e -> m b) (b -> m k)

deriving instance Functor m => Functor (Catch e m)

instance HFunctor (Catch e) where
  hmap f (Catch m h k) = Catch (f m) (f . h) (f . k)

instance Effect (Catch e) where
  handle state handler (Catch m h k) = Catch (handler (m <$ state)) (handler . (<$ state) . h) (handler . fmap k)


-- | Run a computation which can throw errors with a handler to run on error.
--
-- Errors thrown by the handler will escape up to the nearest enclosing 'catchError' (if any).
-- Note that this effect does /not/ handle errors thrown from impure contexts such as IO,
-- nor will it handle exceptions thrown from pure code. If you need to handle IO-based errors,
-- consider if 'Control.Effect.Resource' fits your use case; if not, use 'Control.Monad.IO.Class.liftIO' with
-- 'Control.Exception.try' or use 'Control.Exception.catch' from outside the effect invocation.
--
-- @
-- runError ('throwError' e `catchError` f) = runError (f e)
-- @
--
-- @since 0.1.0.0
catchError :: Has (Catch e) sig m => m a -> (e -> m a) -> m a
catchError m h = send (Catch m h pure)


-- Properties

-- | 'catchError' intercepts 'throwError'.
--
-- @since 1.0.0.0
catchError_interception :: (Has (Catch e) sig m, Has (Throw e) sig m) => (b -> b -> prop) -> (m a -> b) -> e -> (e -> m a) -> prop
catchError_interception (===) runCatch e f = runCatch (throwError e `catchError` f) === runCatch (f e)
