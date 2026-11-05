{-# LANGUAGE GHC2024 #-}
{-# LANGUAGE DerivingStrategies #-}
{-# LANGUAGE GeneralisedNewtypeDeriving #-}
{-# LANGUAGE ImportQualifiedPost #-}
{-# LANGUAGE OverloadedLabels #-}
{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE StrictData #-}
{-# LANGUAGE NoFieldSelectors #-}
{-# LANGUAGE OverloadedStrings #-}

module Main (main) where

import Control.Monad
import Data.Char
import Data.GI.Base (AttrOp (..), new, on)
import Data.Map (Map)
import Data.Map qualified as Map
import Data.Text (Text, pack)
import Data.Time.Clock (getCurrentTime)
import Data.Time.Clock.POSIX (POSIXTime, getPOSIXTime)
import Foreign.C.Types (CLong (..), CULong (..))
import GI.Adw qualified as Adw
import GI.Gio qualified as Gio
import GI.Gtk qualified as Gtk
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

activate :: Adw.Application -> IO ()
activate app = do
  header <- new Adw.HeaderBar []
  toolbar <- new Adw.ToolbarView []
  Adw.toolbarViewAddTopBar toolbar header
  window <-
    new
      Adw.ApplicationWindow
      [ #application := app,
        #title := pack "Todos",
        #defaultWidth := 480,
        #defaultHeight := 640,
        #content := toolbar
      ]
  Gtk.windowPresent window

newtype TodoId = TodoId Word
  deriving stock (Show)
  deriving newtype (Eq, Ord)

data Todo = Todo
  { id :: TodoId,
    title :: Text,
    done :: Bool
  }
  deriving stock (Eq, Show)

data Model = Model
  { todos :: Map TodoId Todo,
    nextId :: TodoId
  }
  deriving stock (Eq, Show)

data Effect = Save [Todo]
  deriving stock (Eq, Show)

init :: Model
init =
  Model
    { todos = Map.empty,
      nextId = TodoId 0
    }

data Message
  = Add Text
  | SetDoneStatus TodoId Bool
  deriving stock (Eq, Ord)

update :: Message -> Model -> (Model, [Effect])
update message model = case message of
  Add raw ->
    let text = Text.strip raw
         todoId@(TodoId n) = model.nextId
	 todo = Todo{ id = todoId, title = text, done = False }
    in if Text.null text
    then (model, [])
    else
      withTodos
        (Map.insert todo.id todo)
	model{ nextId = TodoId (n + 1)}
  SetDoneStatus todoId value ->
    withTodos (Map.adjust (\todo -> todo { done = value }) todoId) model
where
  withTodos f changed =
    let result = changed {todos = f changed.todos}
    in if result.todos == model.todos
        then (result, [])
	else (result, [Save (Map.elems result.todos)])

main :: IO ()
main = do
  app <- new Adw.Application [#applicationId := pack "gt.rotta.Todo"]
  _ <- on app #activate (activate app)

  _ <- Gio.applicationRun app Nothing

  void initialize
  deviceCount <- countDevices
  print deviceCount

  -- Device 2 is UM-ONE (maybe)
  deviceInfo <- getDeviceInfo 2
  print deviceInfo

  stream <- getStream

  gmReset stream

  noteOn stream

  void terminate

  putStrLn "asdasd"

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
