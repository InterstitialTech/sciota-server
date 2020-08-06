module EditDevice exposing (Command(..), Model, Msg(..), initFull, initNew, setId, update, view)

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
    = OnMarkdownInput String
    | OnNameChanged String
    | SavePress
    | DonePress
    | DeletePress
    | ViewPress


type alias Model =
    { id : Maybe Int
    , name : String
    , md : String
    }


type Command
    = None
    | Save Data.SaveDevice
    | Done
    | View Data.SaveDevice
    | Delete Int


view : Model -> Element Msg
view model =
    E.column
        [ E.width E.fill ]
        [ E.row [ E.width E.fill ]
            [ EI.button Common.buttonStyle { onPress = Just SavePress, label = E.text "Save" }
            , EI.button Common.buttonStyle { onPress = Just DonePress, label = E.text "Done" }
            , EI.button Common.buttonStyle { onPress = Just ViewPress, label = E.text "View" }
            , EI.button (E.alignRight :: Common.buttonStyle) { onPress = Just DeletePress, label = E.text "Delete" }
            ]
        , EI.text []
            { onChange = OnNameChanged
            , text = model.name
            , placeholder = Nothing
            , label = EI.labelLeft [] (E.text "name")
            }
        , E.row [ E.width E.fill ]
            [ EI.multiline [ E.width (E.px 400) ]
                { onChange = OnMarkdownInput
                , text = model.md
                , placeholder = Nothing
                , label = EI.labelHidden "Markdown input"
                , spellcheck = False
                }
            ]
        ]


initFull : Data.Device -> Model
initFull zk =
    { id = Just zk.id
    , name = zk.name
    , md = zk.description
    }


initNew : Model
initNew =
    { id = Nothing
    , name = ""
    , md = ""
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
                , name = model.name
                , description = model.md
                }
            )

        ViewPress ->
            ( model
            , View
                { id = model.id
                , name = model.name
                , description = model.md
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

        OnNameChanged t ->
            ( { model | name = t }, None )

        OnMarkdownInput newMarkdown ->
            ( { model
                | md = newMarkdown
              }
            , None
            )
