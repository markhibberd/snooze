{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE PackageImports #-}
module Snooze.Url (
    Path(pathToString)
  , Url(urlToRequest)
  , url
  , path
  , pathRaw
  ) where

import           Blaze.ByteString.Builder (toLazyByteString)

import           Data.ByteString.Lazy.Char8 as BSL
import           Data.String (String)
import           Data.Text as T

import           Network.HTTP.Client (Request, parseUrl)
import           Network.HTTP.Types.URI (encodePathSegmentsRelative)

import           P


newtype Url = Url {
    urlToRequest :: Request
  } deriving (Show)

-- | Represents _just_ the relative path of a URL.
--
-- Invariant: Will _never_ start with a leading slash.
newtype Path = Path {
    pathToString :: String
  } deriving (Eq, Show)

-- | Construct a 'Url' from a base URL and a valid 'Path'.
url :: Text -> Path -> Maybe Url
url b (Path p) =
  fmap Url . parseUrl $ T.unpack (stripTrailingSlash b) <> "/" <> p
  where
    stripTrailingSlash = T.dropWhileEnd (== '/')

-- | Construct a safe 'Path' from unescaped segments.
--
-- This supports a limited "safe" set of paths, which includes strips blank segments.
path :: [Text] -> Path
path =
  Path . BSL.unpack . toLazyByteString . encodePathSegmentsRelative . P.filter (not . T.null)

-- | Construct a 'Path' from an escaped 'Text'.
--
-- NOTE: This will not escape anything, see 'path'.
pathRaw :: Text -> Path
pathRaw =
  Path . T.unpack . T.dropWhile (== '/')
