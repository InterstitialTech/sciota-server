module Data exposing (..)

import Json.Decode as JD
import Json.Encode as JE


type alias Login =
    { uid : String
    , pwd : String
    }


type alias Device =
    { id : Int
    , user : Int
    , name : String
    , description : String
    , createdate : Int
    , changeddate : Int
    }


type alias SaveDevice =
    { id : Maybe Int
    , name : String
    , description : String
    }


type alias Sensor =
    { id : Int
    , device : Int
    , name : String
    , description : String
    , createdate : Int
    , changeddate : Int
    }


type alias SaveSensor =
    { id : Maybe Int
    , device : Int
    , name : String
    , description : String
    }


type alias SaveMeasurement =
    { value : Float
    , sensor : Int
    , measuredate : Int
    }


type alias Measurement =
    { id : Int
    , sensor : Int
    , value : Float
    , createdate : Int
    , measuredate : Int
    }


type alias MeasurementQuery =
    { sensor : Int
    , enddate : Maybe Int
    , lengthOfTime : Maybe Int
    }


encodeSaveDevice : SaveDevice -> JE.Value
encodeSaveDevice device =
    JE.object <|
        (Maybe.map (\id -> [ ( "id", JE.int id ) ]) device.id
            |> Maybe.withDefault []
        )
            ++ [ ( "name", JE.string device.name )
               , ( "description", JE.string device.description )
               ]


encodeSaveSensor : SaveSensor -> JE.Value
encodeSaveSensor sensor =
    JE.object <|
        (Maybe.map (\id -> [ ( "id", JE.int id ) ]) sensor.id
            |> Maybe.withDefault []
        )
            ++ [ ( "device", JE.int sensor.device )
               , ( "name", JE.string sensor.name )
               , ( "description", JE.string sensor.description )
               ]


encodeSaveMeasurement : SaveMeasurement -> JE.Value
encodeSaveMeasurement m =
    JE.object
        [ ( "sensor", JE.int m.sensor )
        , ( "value", JE.float m.value )
        , ( "measuredate", JE.int m.measuredate )
        ]


encodeMeasurementQuery : MeasurementQuery -> JE.Value
encodeMeasurementQuery query =
    JE.object
        (List.filterMap identity
            [ Just ( "sensor", JE.int query.sensor )
            , Maybe.map
                (\ed ->
                    ( "enddate", JE.int ed )
                )
                query.enddate
            , Maybe.map
                (\lengthOfTime ->
                    ( "lengthOfTime", JE.int lengthOfTime )
                )
                query.lengthOfTime
            ]
        )


decodeDevice : JD.Decoder Device
decodeDevice =
    JD.map6 Device
        (JD.field "id" JD.int)
        (JD.field "user" JD.int)
        (JD.field "name" JD.string)
        (JD.field "description" JD.string)
        (JD.field "createdate" JD.int)
        (JD.field "changeddate" JD.int)


decodeSensor : JD.Decoder Sensor
decodeSensor =
    JD.map6 Sensor
        (JD.field "id" JD.int)
        (JD.field "device" JD.int)
        (JD.field "name" JD.string)
        (JD.field "description" JD.string)
        (JD.field "createdate" JD.int)
        (JD.field "changeddate" JD.int)


decodeMeasurement : JD.Decoder Measurement
decodeMeasurement =
    JD.map5 Measurement
        (JD.field "id" JD.int)
        (JD.field "sensor" JD.int)
        (JD.field "value" JD.float)
        (JD.field "createdate" JD.int)
        (JD.field "measuredate" JD.int)
