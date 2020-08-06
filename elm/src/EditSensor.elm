module EditSensor exposing (Command(..), Model, Msg(..), init, initNew, setId, update, view)

import Common
import Data
import Dict exposing (Dict)
import Element as E exposing (Element)
import Element.Background as EBk
import Element.Border as EBd
import Element.Font as Font
import Element.Input as EI
import Element.Region as ER
import Html exposing (Attribute, Html)
import Html.Attributes
import Markdown.Block as Block exposing (Block, Inline, ListItem(..), Task(..))
import Markdown.Html
import Markdown.Parser
import Markdown.Renderer
import Schelme.Show exposing (showTerm)


type Msg
    = OnDescriptionInput String
    | OnTitleChanged String
    | SavePress
    | DonePress
    | DeletePress


type alias Model =
    { id : Maybe Int
    , device : Data.Device
    , name : String
    , description : String
    }


type Command
    = None
    | Save Data.SaveSensor
    | Done
    | Delete Int


view : Model -> Element Msg
view model =
    E.column
        [ E.width E.fill ]
        [ E.text "Edit Sensor"
        , E.row [ E.width E.fill ]
            [ EI.button Common.buttonStyle { onPress = Just SavePress, label = E.text "Save" }
            , EI.button Common.buttonStyle { onPress = Just DonePress, label = E.text "Done" }
            , EI.button (E.alignRight :: Common.buttonStyle) { onPress = Just DeletePress, label = E.text "Delete" }
            ]
        , EI.text []
            { onChange = OnTitleChanged
            , text = model.name
            , placeholder = Nothing
            , label = EI.labelLeft [] (E.text "name")
            }
        , E.row [ E.width E.fill ]
            [ EI.multiline [ E.width (E.px 400) ]
                { onChange = OnDescriptionInput
                , text = model.description
                , placeholder = Nothing
                , label = EI.labelHidden "Markdown input"
                , spellcheck = False
                }
            ]
        ]


init : Data.Device -> Data.Sensor -> Model
init device sensor =
    { id = Just sensor.id
    , device = device
    , name = sensor.name
    , description = sensor.description
    }


initNew : Data.Device -> Model
initNew device =
    { id = Nothing
    , device = device
    , name = ""
    , description = ""
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
                , device = model.device.id
                , name = model.name
                , description = model.description
                }
            )

        DonePress ->
            ( model, Done )

        DeletePress ->
            case model.id of
                Just id ->
                    ( model, Delete id )

                Nothing ->
                    ( model, None )

        OnTitleChanged t ->
            ( { model | name = t }, None )

        OnDescriptionInput d ->
            ( { model
                | description = d
              }
            , None
            )
