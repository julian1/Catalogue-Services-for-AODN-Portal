{-
    module for Storing a Record to db

-}
{-# LANGUAGE ScopedTypeVariables, OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes #-}

module RecordStore where


import Database.PostgreSQL.Simple as PG
import Database.PostgreSQL.Simple.Types as PG(Only(..))
import Text.RawString.QQ

import Helpers as H -- (parseXML)
import ParseMCP20(parse)
import Record


----------------

{-
    ok - get rid of the title,

    -- should be upsert - and probably the only one.
    -- and return the id
-}


storeUUID conn uuid = do


    -- must get the id, so we can delete all old bits,
    -- this is harder than it looks....
    -- insert or select item, returning id
    -- http://stackoverflow.com/questions/18192570/insert-if-not-exists-else-return-id-in-postgresql

    xs :: [ (Only Integer)] <- PG.query conn
        [r|
            with s as (
                select id
                from record
                where uuid = ?
            ),
            i as (
                insert into record(uuid)
                select ?
                where not exists (select 1 from s)
                returning id
            )
            select id from i
            union all
            select id from s
        |]
        (uuid :: String, uuid :: String)

    let record_id = case xs of
         [] -> -99999 -- avoided because sql will return a value
         [ Only record_id ] -> record_id

    putStrLn $ "record_id is " ++ show record_id
    return record_id



storeDataIdentification conn record_id dataIdentification = do
    print "hi this is dataIdentification"
    {- deleting each time isn't nearly as nice
    -- upsert....
    -- but if there are multiple items......  then we have to do a delete first... in case one has been removed????
    -- Note that we can insert the last modified time in the on conflict clause which is quite nice.
    -}

    xs :: [ (Only Integer)] <- PG.query conn
        [r|
            -- using upsert
            -- we use cte in order not to pass the arguments more than once....
            with a as (
                select
                ? as record_id,
                ? as title,
                ? as abstract,
                ? as jurisdiction_link,
                ? as license_link,
                ? as license_name,
                ? as license_image_link
            )
            insert into data_identification(
                record_id,
                title,
                abstract,
                jurisdiction_link,
                license_link,
                license_name,
                license_image_link
            )
            (select * from a)
            on conflict (record_id)
            do update set
                title = (select title from a),
                abstract = (select abstract from a),
                jurisdiction_link = (select jurisdiction_link from a),
                license_link = (select license_link from a),
                license_name = (select license_name from a),
                license_image_link = (select license_image_link from a)
            returning data_identification.id
        |]
        -- there's a limit of 9 elements in the tuple....
        $ let d = dataIdentification in
        (   record_id :: Integer,
            title d,-- :: String,
            abstract d,-- :: String,
            jurisdictionLink d,-- :: String,
            licenseLink d,-- :: String,
            licenseName d,-- :: String,
            licenseImageLink d--  :: String
        )
    return ()




storeTransferLink conn record_id transferLink = do

    xs :: [ (Only Integer)] <- PG.query conn
        [r|
            with a as (
                select
                ? as record_id,
                ? as protocol,
                ? as linkage,
                ? as description
            )
            insert into transfer_link (
                record_id,
                protocol,
                linkage,
                description
            )
            (select * from a)
            on conflict(record_id, protocol, linkage) -- (my_transfer_protocol_unique_idx )
            do update set
                protocol = (select protocol from a),
                linkage = (select linkage from a),
                description = (select description from a)

            returning transfer_link.id
        |]
        $ let t = transferLink in
        (
            record_id, -- :: Integer,
            protocol t,-- :: String,
            linkage t, -- :: String,
            description t-- :: String
        )
    return ()


storeTransferLinks conn record_id transferLinks = do
    -- mapM (putStrLn.show) transferLinks
    mapM (storeTransferLink conn record_id) transferLinks


{-
data DataParameter = DataParameter {

    term :: String,
    url :: String
} deriving (Show, Eq)
-}





storeDataParameter conn record_id dataParameter  = do

    let url_ = url dataParameter

    -- look up the required concept
    -- use separate sql statements to make it easier to write stdout/log
    xs :: [ (Integer, String) ] <- query conn [r|
        select id, label 
        from concept where url = ?
        |]
        (Only url_)

    -- putStrLn $ (show.length) xs

    -- make sure we found the concept
    case length xs of
      1 -> do
        -- store the concept
        let (concept_id, concept_label) : _ = xs
        PG.execute conn [r|
          insert into data_parameter(concept_id, record_id)
          values (?, ?)
            -- the same parameter gets repeated in the record because of poor modelling
          on conflict
          do nothing
        |] (concept_id :: Integer, record_id:: Integer)
        return ()

      0 -> putStrLn $ "dataParameter '" ++ url_ ++ "' not found!"
      _ -> putStrLn $ "dataParameter '" ++ url_ ++ "' found multiple matches?"
{-
-}

    return ()
{- 
    -- look up the required concept
    -- think we want to do this separately 
    xs :: [ (Integer, String) ] <- query conn "select id, label from concept where url = ?" (Only url)
    -- putStrLn $ (show.length) xs
    case length xs of
      1 -> do
        -- store the concept
        let (concept_id, concept_label) : _ = xs
        PG.execute conn [r|
          insert into facet(concept_id, record_id)
          values (?, (select record.id from record where record.uuid = ?))
          on conflict
          do nothing
        |] (concept_id :: Integer, uuid :: String)
        return ()

      0 -> putStrLn $ "dataParameter '" ++ url ++ "' not found!"
      _ -> putStrLn $ "dataParameter '" ++ url ++ "' found multiple matches?"

-}


storeDataParameters conn record_id dataParameters = do
    -- delete....
    -- TODO IMPORTANT - should remove the uuid first...
    -- dataParameters <- runX (parseXML recordText >>> parseDataParameters)
    -- putStrLn $ "data parameter count: " ++ (show.length) dataParameters
    -- mapM (putStrLn.show) dataParameters
    mapM (storeDataParameter conn record_id) dataParameters


storeAll conn record = do

    -- change name storeOrGetUUID
    record_id <- storeUUID conn (Record.uuid record) 

    storeDataIdentification conn record_id (Record.dataIdentification record)

    storeTransferLinks conn record_id (Record.transferLinks record)

    storeDataParameters conn record_id (Record.dataParameters record)


deleteAll conn = do
    -- changeName deleteAllRecords ?
    -- this is useful for testing
    -- truncate record, transfer_link, data_parameter, data_identification   ;

    PG.execute conn [r|
        truncate record, transfer_link, data_parameter, data_identification;
    |] ()

    return ()


main = do
    print "hi"

    conn <- PG.connectPostgreSQL "host='postgres.localnet' dbname='harvest' user='harvest' sslmode='require'"

    recordText <- readFile "./test-data/argo.xml"
    let elts = parseXML recordText
    myRecord <- ParseMCP20.parse elts
    case myRecord of
        Right record -> do
            putStrLn $ showRecord record
            storeAll conn record
            return ()

    PG.close conn



{-
            -- storeUUID conn uuid title = do
            record_id <- storeUUID conn 
            storeDataIdentification conn record_id (Record.dataIdentification record)
            storeTransferLinks conn record_id (Record.transferLinks record)
-}

