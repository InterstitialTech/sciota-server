module ViewMeasurements exposing (Command(..), Model, Msg(..), init, update, view)

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
import Time


type Msg
    = DonePress


type alias Model =
    { id : Int
    , name : String
    , values : List Data.Measurement
    }


type Command
    = None
    | Done


view : Model -> Element Msg
view model =
    E.column
        [ E.width E.fill ]
    <|
        [ E.text <| "Sensor: " ++ model.name
        , E.row [ E.width E.fill ]
            [ EI.button Common.buttonStyle { onPress = Just DonePress, label = E.text "Done" }
            ]
        , E.table [ E.spacing 8 ]
            { data = model.values
            , columns =
                [ { header = E.text "value"
                  , width = E.shrink
                  , view = \m -> E.text (String.fromFloat m.value)
                  }
                , { header = E.text "measured"
                  , width = E.shrink
                  , view = \m -> Common.dateElt Time.utc <| Time.millisToPosix m.measuredate
                  }
                , { header = E.text "created"
                  , width = E.shrink
                  , view = \m -> Common.dateElt Time.utc <| Time.millisToPosix m.createdate
                  }
                ]
            }
        ]


init : Data.Sensor -> List Data.Measurement -> Model
init sensor measurements =
    { id = sensor.id
    , name = sensor.name
    , values = measurements
    }


update : Msg -> Model -> ( Model, Command )
update msg model =
    case msg of
        DonePress ->
            ( model, Done )
