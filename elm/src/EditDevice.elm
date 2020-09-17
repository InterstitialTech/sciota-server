module EditDevice exposing (Command(..), Model, Msg(..), init, initNew, setId, setSensor, update, view)

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
    = OnDescriptionChanged String
    | OnNameChanged String
    | SavePress
    | DonePress
    | DeletePress
    | ViewPress
    | ESLMsg ESL.Msg


type alias Model =
    { id : Maybe Int
    , name : String
    , description : String
    , esl : ESL.Model
    }


type Command
    = None
    | Save Data.SaveDevice
    | Done
    | View Data.SaveDevice
    | Delete Int
    | EditSensor Data.Sensor
    | ViewSensorMeasurements Data.Sensor
    | NewSensor Int


view : Model -> Element Msg
view model =
    E.column
        [ E.width E.fill, E.padding 10, E.spacing 8 ]
        [ E.row [ E.width E.fill, E.spacing 8 ]
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
                { onChange = OnDescriptionChanged
                , text = model.description
                , placeholder = Nothing
                , label = EI.labelHidden "description"
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
    , description = device.description
    , esl = ESL.init sensors
    }


initNew : Model
initNew =
    { id = Nothing
    , name = ""
    , description = ""
    , esl = ESL.initNew
    }


setId : Model -> Int -> Model
setId model beid =
    { model | id = Just beid }


setSensor : Data.Sensor -> Model -> Model
setSensor sensor model =
    { model
        | esl =
            ESL.setSensor sensor model.esl
    }


update : Msg -> Model -> ( Model, Command )
update msg model =
    case msg of
        SavePress ->
            ( model
            , Save
                { id = model.id
                , name = model.name
                , description = model.description
                }
            )

        ViewPress ->
            ( model
            , View
                { id = model.id
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

        OnNameChanged t ->
            ( { model | name = t }, None )

        OnDescriptionChanged s ->
            ( { model
                | description = s
              }
            , None
            )

        ESLMsg emsg ->
            let
                ( emod, ecmd ) =
                    ESL.update emsg model.esl
            in
            case ecmd of
                ESL.New ->
                    case model.id of
                        Just id ->
                            ( { model | esl = emod }, NewSensor id )

                        Nothing ->
                            ( { model | esl = emod }, None )

                ESL.Edit s ->
                    ( { model | esl = emod }, EditSensor s )

                ESL.ViewMeasurements s ->
                    ( { model | esl = emod }, ViewSensorMeasurements s )
