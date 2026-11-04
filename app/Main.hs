module Main (main) where

import Control.Monad
-- PPEvent,

import Data.ByteString (pack)
import Data.Char
import Lib
import Sound.PortMidi
  ( PMEvent,
    PMStream,
    countDevices,
    getDefaultOutputDeviceID,
    getDeviceInfo,
    getErrorText,
    initialize,
    openOutput,
    terminate,
    writeSysEx,
  )

-- main :: IO ()
main = do
  res <- initialize
  deviceCount <- countDevices
  print deviceCount

  -- Device 2 is UM-ONE (maybe)
  deviceInfo <- getDeviceInfo 2
  print deviceInfo

  stream <- getStream

  let gmReset = map chr [0xF0, 0x7E, 0x7F, 0x09, 0x01, 0xF7]
  putStrLn gmReset
  writeSysExCommand stream gmReset

  resTerm <- terminate

  putStrLn "asdasd"

-- gmReset :: PMEvent
-- gmReset = PPEvent CLong 0xF07E7F09

getStream :: IO (PMStream)
getStream = do
  openRes <- openOutput 2 0
  let stream = case openRes of
        Left _ -> error "rip"
        Right s -> pure s
  stream

-- 0 is the timestamp
writeSysExCommand stream command = void $ writeSysEx stream 0 command
