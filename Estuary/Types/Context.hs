module Estuary.Types.Context where

import Data.Time
import qualified Sound.Tidal.Context as Tidal
import Estuary.Tidal.Types
import Estuary.Types.Language

data Context = Context {
  language :: Language,
  startTime :: UTCTime,
  tempo :: Tidal.Tempo,
  pattern :: Tidal.ParamPattern,
  webDirtOn :: Bool,
  superDirtOn :: Bool,
  peakLevels :: [Double],
  rmsLevels :: [Double],
  wsStatus :: String,
  clientCount :: Int
  }

emptyContext :: UTCTime -> Context
emptyContext now = Context {
  language = English,
  startTime = now,
  tempo = Tidal.Tempo now 0.0 0.5 False 0.2,
  pattern = Tidal.silence,
  webDirtOn = True,
  superDirtOn = False,
  peakLevels = [],
  rmsLevels = [],
  wsStatus = "",
  clientCount = 0
}

type ContextChange = Context -> Context

setLanguage :: Language -> ContextChange
setLanguage x c = c { language = x }

setPeakLevels :: [Double] -> ContextChange
setPeakLevels xs c = c { peakLevels = xs }

setRmsLevels :: [Double] -> ContextChange
setRmsLevels xs c = c { rmsLevels = xs }

setClientCount :: Int -> ContextChange
setClientCount x c = c { clientCount = x }

setPattern :: Tidal.ParamPattern -> ContextChange
setPattern x c = c { pattern = x }
