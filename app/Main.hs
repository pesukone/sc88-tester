{-# LANGUAGE ImportQualifiedPost #-}

module Main (main) where

import Control.Monad
import Data.Char
import Data.Time.Clock (getCurrentTime)
import Data.Time.Clock.POSIX (POSIXTime, getPOSIXTime)
import Foreign.C.Types (CLong (..), CULong (..))
import GI.Adw qualified as Adw
import GI.Gtk qualified as Gtk
import GI.Gio qualified as Gio
import Lib
import Numeric (showHex)
import Sound.PortMidi
  ( PMEvent (..),
    PMStream,
    countDevices,
    getDefaultOutputDeviceID,
    getDeviceInfo,
    getErrorText,
    initialize,
    openOutput,
    terminate,
    writeEvents,
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

  gmReset stream

  noteOn stream

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
writeSysExCommand :: PMStream -> String -> IO ()
writeSysExCommand stream command = void $ writeSysEx stream 0 command

writeMidiEvent :: PMStream -> PMEvent -> IO ()
writeMidiEvent stream event = do
  putStrLn $ show event
  putStrLn $ showHex (message event) ""
  writeRes <- writeEvents stream [event]
  case writeRes of
    Left e -> putStrLn $ show e
    Right s -> putStrLn $ show s

-- noteOnEvent :: PMEvent
-- noteOnEvent = PMEvent 0x906464 getCurrentTime

getTimeStamp :: IO (Integer)
getTimeStamp = do
  timeStamp <- getPOSIXTime
  return $ round (1000 * timeStamp)

createMidiEvent :: CLong -> IO (PMEvent)
createMidiEvent command = do
  timeStamp <- getTimeStamp
  return $ PMEvent command (fromIntegral timeStamp :: CULong)

noteOn stream = do
  noteOnEvent <- createMidiEvent 0x646490
  writeMidiEvent stream noteOnEvent

-- writeMidiEvent stream (PMEvent 0x906464 timeStamp)

gmReset :: PMStream -> IO ()
gmReset stream = writeSysExCommand stream gmResetCommand
  where
    gmResetCommand = map chr [0xF0, 0x7E, 0x7F, 0x09, 0x01, 0xF7]
