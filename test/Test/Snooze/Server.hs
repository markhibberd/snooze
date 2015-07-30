{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE OverloadedStrings #-}
module Test.Snooze.Server where

import           Control.Concurrent
import           Control.Exception

import           Data.Text as T

import           Network.Wai (rawPathInfo)

import           P

import           Snooze.Url

import           System.IO
import           System.Random (randomRIO)

import           Web.Scotty


withServer :: ScottyM () -> (Text -> IO a) -> IO a
withServer app f = do
  -- FIX Find an open port rather than failing randomly
  port <- randomRIO (10100, 65534)
  let url' = "http://localhost:" <> (T.pack $ show port) <> "/"
  bracket
    (forkIO . scotty port $ app)
    killThread
    (const $ f url')
  
withServer' :: Path -> ScottyM () -> (Url -> IO a) -> IO a
withServer' p s a =
  withServer s $ \b -> maybe (fail $ "Bad URL" <> T.unpack b) pure (url b p) >>= a


-- Unfortunately the "Web.Scotty.Route" 'literal' match doesn't always match
pathRoutePattern :: Path -> RoutePattern
pathRoutePattern p =
  function $ \r ->
    if (show $ "/" <> pathToString p) == (show $ rawPathInfo r) then (Just []) else Nothing
