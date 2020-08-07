module EditDevice exposing (Command(..), Model, Msg(..), init, initNew, setId, update, view)

import Common
import Data
import Dict exposing (Dict)
import EditSensorListing as ESL
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



{-

   ( EditSensorListingMsg em, EditSensorListing es login ) ->
       let
           ( emod, ecmd ) =
               EditSensorListing.update em es
       in
       case ecmd of
           EditSensorListing.New ->
               ( { model | state = EditSensor (EditSensor.initNew emod.device) login }, Cmd.none )

           EditSensorListing.Selected s ->
               ( { model
                   | state = EditSensor (EditSensor.init emod.device s) login
                 }
               , Cmd.none
               )



-}


type Msg
    = OnMarkdownInput String
    | OnNameChanged String
    | SavePress
    | DonePress
    | DeletePress
    | ViewPress
    | ESLMsg ESL.Msg


type alias Model =
    { id : Maybe Int
    , name : String
    , md : String
    , esl : ESL.Model
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
        , E.text "sensors"
        , E.map ESLMsg (ESL.view model.esl)
        ]


init : Data.Device -> List Data.Sensor -> Model
init device sensors =
    { id = Just device.id
    , name = device.name
    , md = device.description
    , esl = ESL.init sensors
    }


initNew : Model
initNew =
    { id = Nothing
    , name = ""
    , md = ""
    , esl = ESL.initNew
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

        ESLMsg emsg ->
            let
                ( emod, ecmd ) =
                    ESL.update emsg model.esl
            in
            ( { model | esl = emod }, None )
