-- |
-- Module      : Crypto.Hash.Types
-- License     : BSD-style
-- Maintainer  : Vincent Hanquez <vincent@snarc.org>
-- Stability   : experimental
-- Portability : unknown
--
-- Crypto hash types definitions
--
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeFamilies #-}
module Crypto.Hash.Types
    ( HashAlgorithm(..)
    , Context(..)
    , Digest(..)
    ) where

import           Crypto.Internal.Imports
import           Crypto.Internal.ByteArray (ByteArrayAccess, Bytes)
import qualified Crypto.Internal.ByteArray as B
import           Foreign.Ptr (Ptr)
import           Basement.Block (Block)
import           Basement.NormalForm (deepseq)
import           GHC.TypeLits (Nat)

-- | Class representing hashing algorithms.
--
-- The interface presented here is update in place
-- and lowlevel. the Hash module takes care of
-- hidding the mutable interface properly.
class HashAlgorithm a where
    -- | Associated type for the block size of the hash algorithm
    type HashBlockSize a :: Nat
    -- | Associated type for the digest size of the hash algorithm
    type HashDigestSize a :: Nat
    -- | Associated type for the internal context size of the hash algorithm
    type HashInternalContextSize a :: Nat

    -- | Get the block size of a hash algorithm
    hashBlockSize           :: a -> Int
    -- | Get the digest size of a hash algorithm
    hashDigestSize          :: a -> Int
    -- | Get the size of the context used for a hash algorithm
    hashInternalContextSize :: a -> Int
    --hashAlgorithmFromProxy  :: Proxy a -> a

    -- | Initialize a context pointer to the initial state of a hash algorithm
    hashInternalInit     :: Ptr (Context a) -> IO ()
    -- | Update the context with some raw data
    hashInternalUpdate   :: Ptr (Context a) -> Ptr Word8 -> Word32 -> IO ()
    -- | Finalize the context and set the digest raw memory to the right value
    hashInternalFinalize :: Ptr (Context a) -> Ptr (Digest a) -> IO ()

{-
hashContextGetAlgorithm :: HashAlgorithm a => Context a -> a
hashContextGetAlgorithm = undefined
-}

-- | Represent a context for a given hash algorithm.
newtype Context a = Context Bytes
    deriving (ByteArrayAccess,NFData)

-- | Represent a digest for a given hash algorithm.
--
-- This type is an instance of 'ByteArrayAccess' from package
-- <https://hackage.haskell.org/package/memory memory>.
-- Module "Data.ByteArray" provides many primitives to work with those values
-- including conversion to other types.
--
-- Creating a digest from a bytearray is also possible with function
-- 'Crypto.Hash.digestFromByteString'.
newtype Digest a = Digest (Block Word8)
    deriving (Eq,Ord,ByteArrayAccess)

instance NFData (Digest a) where
    rnf (Digest u) = u `deepseq` ()

instance Show (Digest a) where
    show (Digest bs) = map (toEnum . fromIntegral)
                     $ B.unpack (B.convertToBase B.Base16 bs :: Bytes)
