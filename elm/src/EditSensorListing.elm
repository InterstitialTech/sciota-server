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

        a :: b ->
            { model | sensors = l ++ sensor :: b }


view : Model -> Element Msg
view model =
    E.column [ E.spacing 8, E.padding 8 ] <|
        E.row [ E.spacing 20 ]
            [ E.text "Select a sensor"
            , EI.button Common.buttonStyle { onPress = Just NewPress, label = E.text "new" }
            ]
            :: List.map
                (\e ->
                    E.row [ E.spacing 8 ]
                        [ E.row [ Font.bold ] [ E.text <| String.fromInt e.id ]
                        , E.text " - "
                        , E.text e.name
                        , EI.button Common.buttonStyle { onPress = Just (SelectPress e), label = E.text "edit" }
                        , EI.button Common.buttonStyle { onPress = Just (ViewPress e), label = E.text "view" }
                        ]
                )
                model.sensors


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
