module Estuary.Types.EnsembleState where

import Data.Map
import qualified Sound.Tidal.Tempo as Tidal
import Data.Time
import Data.Time.Clock.POSIX

import Estuary.Types.EnsembleRequest
import Estuary.Types.EnsembleResponse
import Estuary.Types.Definition
import Estuary.Types.View
import Estuary.Types.Sited
import Estuary.Types.EditOrEval
import qualified Estuary.Types.Terminal as Terminal

data EnsembleState = EnsembleState {
  ensembleName :: String,
  userHandle :: String,
  zones :: Map Int Definition,
  publishedViews :: Map String View,
  defaultView :: View,
  customView :: View,
  activeView :: Maybe String, -- Nothing = defaultView, Just "" = CustomView, Just x = from publishedViews
  tempo :: Tidal.Tempo
}

newEnsembleState :: String -> UTCTime -> EnsembleState
newEnsembleState x now = EnsembleState {
  ensembleName = x,
  userHandle = "",
  zones = empty,
  publishedViews = empty,
  defaultView = emptyView,
  customView = emptyView,
  activeView = Nothing,
  tempo = Tidal.Tempo { Tidal.at=now, Tidal.beat=0.0, Tidal.cps=0.5, Tidal.paused=False, Tidal.clockLatency=0.0 }
}

getActiveView :: EnsembleState -> View
getActiveView e = f (activeView e)
  where f Nothing = defaultView e
        f (Just "") = customView e
        f (Just x) = findWithDefault emptyView x (publishedViews e)

commandsToStateChanges :: Terminal.Command -> EnsembleState -> EnsembleState
commandsToStateChanges (Terminal.SetView v) es = es { customView = v, activeView = Just "" }
commandsToStateChanges Terminal.StandardView es = es { customView = standardView, activeView = Just "" }
commandsToStateChanges (Terminal.PresetView v) es = es { customView = presetView v, activeView = Just ""}
commandsToStateChanges Terminal.DefaultView es = es { activeView = Nothing }
commandsToStateChanges (Terminal.ActiveView x) es = es { activeView = Just x }
commandsToStateChanges (Terminal.PublishView x) es = es { publishedViews = newViews, activeView = Just x }
  where newViews = insert x (getActiveView es) (publishedViews es)
commandsToStateChanges Terminal.PublishDefaultView es = es { defaultView = getActiveView es }
commandsToStateChanges (Terminal.DeleteView x) es = es { publishedViews = delete x (publishedViews es) }
commandsToStateChanges _ es = es

requestsToStateChanges :: EnsembleRequest Definition -> EnsembleState -> EnsembleState
requestsToStateChanges (ZoneRequest (Sited n (Edit x))) es = es { zones = insert n x (zones es) }
requestsToStateChanges _ es = es

responsesToStateChanges :: EnsembleResponse Definition -> EnsembleState -> EnsembleState
responsesToStateChanges (ZoneResponse (Sited n (Edit v))) es = es { zones = newZones }
  where newZones = insert n v (zones es)
responsesToStateChanges (View (Sited s v)) es = es { publishedViews = newViews }
  where newViews = insert s v (publishedViews es)
responsesToStateChanges (DefaultView v) es = es { defaultView = v }
responsesToStateChanges (Tempo c a b) es = es { tempo = (tempo es) { Tidal.cps = c } }
  where a' = (posixSecondsToUTCTime . fromRational) a
responsesToStateChanges _ es = es

commandsToRequests :: EnsembleState -> Terminal.Command -> Maybe (EnsembleRequest Definition)
commandsToRequests es (Terminal.PublishView x) = Just (PublishView (Sited x (getActiveView es)))
commandsToRequests es (Terminal.PublishDefaultView) = Just (PublishDefaultView (getActiveView es))
commandsToRequests es (Terminal.GetView x) = Just (GetView x)
commandsToRequests es Terminal.ListViews = Just ListViews
commandsToRequests es (Terminal.DeleteView x) = Just (DeleteView x)
commandsToRequests es (Terminal.Chat x) = Just (SendChat (userHandle es) x)
commandsToRequests _ _ = Nothing

messageForEnsembleResponse :: EnsembleResponse Definition -> Maybe String
messageForEnsembleResponse (Chat name msg) = Just $ name ++ " chats: " ++ msg
messageForEnsembleResponse (ViewList xs) = Just $ "Views: " ++ (show xs)
messageForEnsembleResponse (View (Sited x _)) = Just $ "received view " ++ x
messageForEnsembleResponse (Tempo c a b) = Just $ "received new tempo " ++ (show c) ++ " " ++ (show a) ++ " " ++ (show b)
messageForEnsembleResponse _ = Nothing
