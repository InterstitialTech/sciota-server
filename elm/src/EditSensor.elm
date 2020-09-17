module EditSensor exposing (Command(..), Model, Msg(..), init, initNew, setId, update, view)

import Common
import Data
import Dict exposing (Dict)
import Element as E exposing (Element)
import Element.Background as EBk
import Element.Border as EBd
import Element.Font as EF
import Element.Input as EI
import Element.Region as ER
import Html exposing (Attribute, Html)
import Html.Attributes
import Markdown.Block as Block exposing (Block, Inline, ListItem(..), Task(..))
import Markdown.Html
import Markdown.Parser
import Markdown.Renderer
import Schelme.Show exposing (showTerm)
import TangoColors as TC


type Msg
    = OnDescriptionChanged String
    | OnNameChanged String
    | OnValueChanged String
    | AddPress
    | SavePress
    | DeletePress
    | DonePress


type alias Model =
    { id : Maybe Int
    , deviceid : Int
    , name : String
    , description : String
    , value : String
    , valuef : Maybe Float
    }


type Command
    = None
    | Save Data.SaveSensor
    | AddMeasurement Int Float
    | Delete Int
    | Cancel


view : Model -> Element Msg
view model =
    E.column
        [ E.width E.fill ]
        [ E.text "Edit Sensor"
        , E.row [ E.width E.fill ]
            [ EI.button Common.buttonStyle { onPress = Just SavePress, label = E.text "Ok" }
            , EI.button Common.buttonStyle { onPress = Just DonePress, label = E.text "Cancel" }
            , EI.button Common.buttonStyle { onPress = Just DeletePress, label = E.text "Delete" }
            ]
        , EI.text []
            { onChange = OnNameChanged
            , text = model.name
            , placeholder = Nothing
            , label = EI.labelLeft [] (E.text "name")
            }
        , E.row [ E.width E.fill ]
            [ EI.multiline [ E.width (E.px 400) ]
                { onChange = OnDescriptionChanged
                , text = model.description
                , placeholder = Nothing
                , label = EI.labelHidden "Description"
                , spellcheck = False
                }
            ]
        , case model.id of
            Just id ->
                E.row []
                    [ EI.text
                        (if String.toFloat model.value == model.valuef then
                            [ EF.color TC.red ]

                         else
                            []
                        )
                        { onChange = OnValueChanged
                        , text = model.value
                        , placeholder = Nothing
                        , label = EI.labelLeft [] (E.text "measurement")
                        }
                    , EI.button Common.buttonStyle { onPress = Just AddPress, label = E.text "Add" }
                    ]

            Nothing ->
                E.none
        ]


init : Data.Sensor -> Model
init sensor =
    { id = Just sensor.id
    , deviceid = sensor.device
    , name = sensor.name
    , description = sensor.description
    , value = ""
    , valuef = Nothing
    }


initNew : Int -> Model
initNew deviceid =
    { id = Nothing
    , deviceid = deviceid
    , name = ""
    , description = ""
    , value = ""
    , valuef = Nothing
    }


setId : Model -> Int -> Model
setId model beid =
    { model | id = Just beid }


update : Msg -> Model -> ( Model, Command )
update msg model =
    case msg of
        SavePress ->
            ( model
            , Save
                { id = model.id
                , device = model.deviceid
                , name = model.name
                , description = model.description
                }
            )

        DonePress ->
            ( model, Cancel )

        DeletePress ->
            ( model, model.id |> Maybe.map Delete |> Maybe.withDefault None )

        OnNameChanged t ->
            ( { model | name = t }, None )

        OnDescriptionChanged d ->
            ( { model
                | description = d
              }
            , None
            )

        OnValueChanged v ->
            ( { model
                | value = v
                , valuef = String.toFloat v
              }
            , None
            )

        AddPress ->
            case Debug.log "addpress" ( model.id, model.valuef ) of
                ( Just id, Just v ) ->
                    ( model, AddMeasurement id v )

                _ ->
                    ( model, None )
