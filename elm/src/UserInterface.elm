module UserInterface exposing (SendMsg(..), ServerResponse(..), encodeEmail, encodeSendMsg, serverResponseDecoder)

import Data
import Json.Decode as JD
import Json.Encode as JE


type SendMsg
    = Register String
    | Login
    | GetDeviceListing
    | GetDevice Int
    | SaveDevice Data.SaveDevice
    | DeleteDevice Int
    | GetSensorListing (Maybe Int)
    | GetSensor Int
    | SaveSensor Data.SaveSensor
    | DeleteSensor Int
    | GetMeasurementListing Data.MeasurementQuery
    | SaveMeasurement Data.SaveMeasurement


type ServerResponse
    = ServerError String
    | RegistrationSent
    | UserExists
    | UnregisteredUser
    | InvalidUserOrPwd
    | LoggedIn
    | DeviceListing (List Data.Device)
    | Device Data.Device
    | DeviceSaved Int
    | DeviceDeleted Int
    | SensorListing (List Data.Sensor)
    | Sensor Data.Sensor
    | SensorSaved Data.Sensor
    | SensorDeleted Int
    | MeasurementListing (List Data.Measurement)
    | Measurement Data.Measurement
    | MeasurementSaved Int


encodeSendMsg : SendMsg -> String -> String -> JE.Value
encodeSendMsg sm uid pwd =
    case sm of
        Register email ->
            JE.object
                [ ( "what", JE.string "register" )
                , ( "uid", JE.string uid )
                , ( "pwd", JE.string pwd )
                , ( "data", encodeEmail email )
                ]

        Login ->
            JE.object
                [ ( "what", JE.string "login" )
                , ( "uid", JE.string uid )
                , ( "pwd", JE.string pwd )
                ]

        GetDeviceListing ->
            JE.object
                [ ( "what", JE.string "getdevicelisting" )
                , ( "uid", JE.string uid )
                , ( "pwd", JE.string pwd )
                ]

        GetDevice id ->
            JE.object
                [ ( "what", JE.string "getdevice" )
                , ( "uid", JE.string uid )
                , ( "pwd", JE.string pwd )
                , ( "data", JE.int id )
                ]

        SaveDevice device ->
            JE.object
                [ ( "what", JE.string "savedevice" )
                , ( "uid", JE.string uid )
                , ( "pwd", JE.string pwd )
                , ( "data", Data.encodeSaveDevice device )
                ]

        DeleteDevice id ->
            JE.object
                [ ( "what", JE.string "deletedevice" )
                , ( "uid", JE.string uid )
                , ( "pwd", JE.string pwd )
                , ( "data", JE.int id )
                ]

        GetSensorListing mbid ->
            JE.object <|
                [ ( "what", JE.string "getsensorlisting" )
                , ( "uid", JE.string uid )
                , ( "pwd", JE.string pwd )
                ]
                    ++ (mbid
                            |> Maybe.map
                                (\id ->
                                    [ ( "data", JE.int id ) ]
                                )
                            |> Maybe.withDefault []
                       )

        GetSensor id ->
            JE.object
                [ ( "what", JE.string "getsensor" )
                , ( "uid", JE.string uid )
                , ( "pwd", JE.string pwd )
                , ( "data", JE.int id )
                ]

        SaveSensor sensor ->
            JE.object
                [ ( "what", JE.string "savesensor" )
                , ( "uid", JE.string uid )
                , ( "pwd", JE.string pwd )
                , ( "data", Data.encodeSaveSensor sensor )
                ]

        SaveMeasurement m ->
            JE.object
                [ ( "what", JE.string "savemeasurement" )
                , ( "uid", JE.string uid )
                , ( "pwd", JE.string pwd )
                , ( "data", Data.encodeSaveMeasurement m )
                ]

        DeleteSensor id ->
            JE.object
                [ ( "what", JE.string "deletesensor" )
                , ( "uid", JE.string uid )
                , ( "pwd", JE.string pwd )
                , ( "data", JE.int id )
                ]

        GetMeasurementListing query ->
            JE.object
                [ ( "what", JE.string "getmeasurementlisting" )
                , ( "uid", JE.string uid )
                , ( "pwd", JE.string pwd )
                , ( "data", Data.encodeMeasurementQuery query )
                ]


encodeEmail : String -> JE.Value
encodeEmail email =
    JE.object
        [ ( "email", JE.string email )
        ]


serverResponseDecoder : JD.Decoder ServerResponse
serverResponseDecoder =
    JD.andThen
        (\what ->
            case what of
                "server error" ->
                    JD.map ServerError (JD.at [ "content" ] JD.string)

                "registration sent" ->
                    JD.succeed RegistrationSent

                "unregistered user" ->
                    JD.succeed UnregisteredUser

                "user exists" ->
                    JD.succeed UserExists

                "logged in" ->
                    JD.succeed LoggedIn

                "invalid user or pwd" ->
                    JD.succeed InvalidUserOrPwd

                "devicelisting" ->
                    JD.map DeviceListing (JD.at [ "content" ] <| JD.list Data.decodeDevice)

                "sensorlisting" ->
                    JD.map SensorListing (JD.at [ "content" ] <| JD.list Data.decodeSensor)

                "measurementlisting" ->
                    JD.map MeasurementListing (JD.at [ "content" ] <| JD.list Data.decodeMeasurement)

                "saveddevice" ->
                    JD.map DeviceSaved (JD.at [ "content" ] <| JD.int)

                "deleteddevice" ->
                    JD.map DeviceDeleted (JD.at [ "content" ] <| JD.int)

                "savedsensor" ->
                    JD.map SensorSaved (JD.at [ "content" ] <| Data.decodeSensor)

                "deletedsensor" ->
                    JD.map SensorDeleted (JD.at [ "content" ] <| JD.int)

                "measurement" ->
                    JD.map Measurement (JD.at [ "content" ] <| Data.decodeMeasurement)

                "savedmeasurement" ->
                    JD.map MeasurementSaved (JD.at [ "content" ] <| JD.int)

                wat ->
                    JD.succeed
                        (ServerError ("invalid 'what' from server: " ++ wat))
        )
        (JD.at [ "what" ]
            JD.string
        )
