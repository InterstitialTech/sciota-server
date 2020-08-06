module EditDeviceListing exposing (..)

import Common
import Data
import Element as E exposing (Element)
import Element.Background as EBk
import Element.Border as EBd
import Element.Font as Font
import Element.Input as EI
import Element.Region
import TangoColors as TC


type Msg
    = SelectPress Data.Device
    | NewPress


type alias Model =
    { devices : List Data.Device
    }


type Command
    = Selected Data.Device
    | New


view : Model -> Element Msg
view model =
    E.column [ E.spacing 8, E.padding 8 ] <|
        E.row [ E.spacing 20 ]
            [ E.text "Select a device"
            , EI.button Common.buttonStyle { onPress = Just NewPress, label = E.text "new" }
            ]
            :: List.map
                (\e ->
                    E.row [ E.spacing 8 ]
                        [ E.text e.name
                        , EI.button Common.buttonStyle { onPress = Just (SelectPress e), label = E.text "edit" }
                        ]
                )
                model.devices


update : Msg -> Model -> ( Model, Command )
update msg model =
    case msg of
        SelectPress id ->
            ( model
            , Selected id
            )

        NewPress ->
            ( model, New )
