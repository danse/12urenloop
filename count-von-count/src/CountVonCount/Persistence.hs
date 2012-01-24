{-# LANGUAGE OverloadedStrings, ScopedTypeVariables #-}
module CountVonCount.Persistence
    ( module CountVonCount.Persistence.Core
    , Team (..)
    , addLap
    , getTeamByMac
    ) where

import Data.Aeson (ToJSON (..), object, (.=))
import qualified Data.ByteString.Char8 as BC
import qualified Database.MongoDB as MDB

import CountVonCount.Types
import CountVonCount.Persistence.Core

data Team = Team
    { teamId    :: Int
    , teamName  :: String
    , teamLaps  :: Int
    , teamBaton :: Maybe String
    } deriving (Eq, Show, Ord)

instance ToJSON Team where
    toJSON (Team id' name laps baton) = object
        ["id" .= id', "name" .= name, "laps" .= laps, "baton" .= baton]

instance IsDocument Team where
    collection _     = "teams"
    toDocument team  =
        [ "id"    MDB.=: teamId team
        , "name"  MDB.=: teamName team
        , "laps"  MDB.=: teamLaps team
        , "baton" MDB.=: teamBaton team
        ]
    fromDocument doc = Team
        (MDB.at "id" doc)
        (MDB.at "name" doc)
        (MDB.at "laps" doc)
        (MDB.at "baton" doc)

addLap :: Team -> Team
addLap team = team {teamLaps = teamLaps team + 1}

getTeamByMac :: Mac -> Persistence (Maybe (Ref Team, Team))
getTeamByMac m = do
    cursor <- MDB.find $ MDB.select ["baton" MDB.=: BC.unpack m] $ collection x
    docs   <- MDB.rest cursor
    return $ case docs of
        [doc] -> Just (MDB.valueAt "_id" doc, fromDocument doc)
        _     -> Nothing
  where
    x = undefined :: Team