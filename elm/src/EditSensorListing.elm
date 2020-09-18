module EditSensorListing exposing (..)

import Common
import Data
import EditSensor as ES
import Element as E exposing (Element)
import Element.Background as EBk
import Element.Border as EBd
import Element.Font as Font
import Element.Input as EI
import Element.Region
import TangoColors as TC
import Util


type Msg
    = SelectPress Data.Sensor
    | ViewPress Data.Sensor
    | NewPress


type alias Model =
    { sensors : List Data.Sensor
    , edit : Maybe ES.Model
    }


type Command
    = Edit Data.Sensor
    | ViewMeasurements Data.Sensor
    | New


initNew : Model
initNew =
    { sensors = []
    , edit = Nothing
    }


init : List Data.Sensor -> Model
init sensors =
    { sensors = sensors
    , edit = Nothing
    }


setSensor : Data.Sensor -> Model -> Model
setSensor sensor model =
    -- if theres a sensor in the list with this id, replace it.
    let
        ( l, r ) =
            Util.splitAt (\s -> s.id == sensor.id) model.sensors
    in
    case r of
        [] ->
            { model | sensors = sensor :: model.sensors }

        _ :: b ->
            { model | sensors = l ++ sensor :: b }


removeSensor : Int -> Model -> Model
removeSensor sensorid model =
    -- if theres a sensor in the list with this id, replace it.
    let
        ( l, r ) =
            Util.splitAt
                (\s -> s.id == sensorid)
                model.sensors
    in
    { model | sensors = l ++ Util.rest r }


view : Model -> Element Msg
view model =
    E.column [ E.spacing 8, E.padding 8 ] <|
        [ E.row [ E.spacing 20 ]
            [ E.text "Select a sensor"
            , EI.button Common.buttonStyle { onPress = Just NewPress, label = E.text "new" }
            ]
        , E.table [ E.spacing 8 ]
            { data = model.sensors
            , columns =
                [ { header = E.none
                  , width = E.shrink
                  , view =
                        \e ->
                            E.row []
                                [ E.row [ Font.bold ] [ E.text <| String.fromInt e.id ]
                                , E.text " - "
                                ]
                  }
                , { header = E.none
                  , width = E.shrink
                  , view = \e -> E.text e.name
                  }
                , { header = E.none
                  , width = E.shrink
                  , view =
                        \e ->
                            EI.button Common.buttonStyle { onPress = Just (SelectPress e), label = E.text "edit" }
                  }
                , { header = E.none
                  , width = E.shrink
                  , view =
                        \e ->
                            EI.button Common.buttonStyle { onPress = Just (ViewPress e), label = E.text "view" }
                  }
                ]
            }
        ]


update : Msg -> Model -> ( Model, Command )
update msg model =
    case msg of
        SelectPress s ->
            ( model
            , Edit s
            )

        ViewPress s ->
            ( model
            , ViewMeasurements s
            )

        NewPress ->
            ( model, New )
