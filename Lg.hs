{-# LANGUAGE DeriveDataTypeable #-}
{-# LANGUAGE DeriveGeneric      #-}
{-# LANGUAGE OverloadedStrings  #-}
{-# LANGUAGE RecordWildCards    #-}


module Main where


import           Data.Aeson
import qualified Data.ByteString.Lazy as BL
import           Data.Data
import           Data.Maybe
import           Data.Monoid          ((<>))
import qualified Data.Text            as T
import           Data.Time
import           GHC.Generics
import           Options.Applicative  hiding ((<$>), (<*>))
import           System.Directory
import           System.FilePath


data LgOptions
    = LgO
    { lgoDate    :: !(Maybe UTCTime)
    , lgoOutput  :: !(Maybe FilePath)
    , lgoTags    :: ![T.Text]
    , lgoMessage :: !T.Text
    }

data LogEntry
    = Log
    { date    :: !UTCTime
    , tags    :: ![T.Text]
    , message :: !T.Text
    } deriving (Show, Eq, Data, Typeable, Generic)

instance ToJSON LogEntry where
    toJSON     = genericToJSON     defaultOptions
    toEncoding = genericToEncoding defaultOptions

instance FromJSON LogEntry where
    parseJSON = genericParseJSON defaultOptions


main :: IO ()
main = do
    LgO{..} <- execParser opts
    now     <- maybe getCurrentTime return lgoDate
    home    <- getHomeDirectory
    let outputFormat =   home </> "Dropbox" </> "lg" </> "%Y" </> "%m" </> "%d"
                     </> "worklog-%Y-%m-%d.json"
        output = fromMaybe (formatTime defaultTimeLocale outputFormat now)
                           lgoOutput
        lg     = Log now lgoTags lgoMessage
    createDirectoryIfMissing True $ takeDirectory output
    BL.appendFile output $ (`BL.append` "\n") $ encode lg


opts' :: Parser LgOptions
opts'
    =   LgO
    <$> optional (option timeM (  short 'd' <> long "date"
                               <> metavar "YYYY-MM-DDTHH:MM"
                               <> help "The timestamp for the log.\
                                       \ Default is now."))
    <*> optional (strOption (  short 'o' <> long "output"
                            <> metavar "FILENAME"
                            <> help "The file to put the output in.\
                                    \ By default, this is based on the\
                                    \ timestamp, and defaults to\
                                    \ ~/Dropbox/lg/YYYY/MM/DD/\
                                    \worklog-YYYY-MM-DD.json."
                            ))
    <*> many (option (T.pack <$> str) (  short 't' <> long "tag"
                                      <> metavar "TAG"
                                      <> help "A tag to add to the entry."))
    <*> argument (T.pack <$> str) (  metavar "MESSAGE"
                                  <> help "The message to log.")

timeM :: ReadM UTCTime
timeM =   parseTimeM True defaultTimeLocale (iso8601DateFormat (Just "%H:%M"))
      =<< str

opts :: ParserInfo LgOptions
opts = info (helper <*> opts')
        (  fullDesc
        <> progDesc "A description of lots of things."
        <> header "add to a work log"
        )
