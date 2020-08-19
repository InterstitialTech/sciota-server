module ViewMeasurements exposing (Command(..), Model, Msg(..), init, update, view)

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
import LineChart
import LineChart.Area as Area
import LineChart.Axis as Axis
import LineChart.Axis.Intersection as Intersection
import LineChart.Axis.Line as AxisLine
import LineChart.Axis.Range as Range
import LineChart.Axis.Tick as Tick
import LineChart.Axis.Ticks as Ticks
import LineChart.Axis.Title as Title
import LineChart.Axis.Values as Values
import LineChart.Colors as Colors
import LineChart.Container as Container
import LineChart.Dots as Dots
import LineChart.Events as Events
import LineChart.Grid as Grid
import LineChart.Interpolation as Interpolation
import LineChart.Junk as Junk exposing (..)
import LineChart.Legends as Legends
import LineChart.Line as Line
import Markdown.Block as Block exposing (Block, Inline, ListItem(..), Task(..))
import Markdown.Html
import Markdown.Parser
import Markdown.Renderer
import Schelme.Show exposing (showTerm)
import Time


type alias Dimension =
    { width : Float, height : Float }


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
        [ E.width E.fill, E.spacing 8 ]
    <|
        [ E.row []
            [ E.row [ EF.bold ] [ E.text <| "Sensor: " ]
            , E.text model.name
            ]
        , E.row [ E.width E.fill ]
            [ EI.button Common.buttonStyle { onPress = Just DonePress, label = E.text "Done" }
            ]
        , E.table [ E.spacing 8 ]
            { data = model.values
            , columns =
                [ { header = E.row [ EF.bold ] [ E.text "value" ]
                  , width = E.shrink
                  , view = \m -> E.text (String.fromFloat m.value)
                  }
                , { header = E.row [ EF.bold ] [ E.text "measured" ]
                  , width = E.shrink
                  , view = \m -> Common.dateElt Time.utc <| Time.millisToPosix m.measuredate
                  }
                , { header = E.row [ EF.bold ] [ E.text "created" ]
                  , width = E.shrink
                  , view = \m -> Common.dateElt Time.utc <| Time.millisToPosix m.createdate
                  }
                ]
            }
        , measureChart { width = 500, height = 1500 } model.values |> E.html
        ]


measureChart : Dimension -> List Data.Measurement -> Html.Html msg
measureChart dimension measurements =
    LineChart.viewCustom
        { x =
            Axis.custom
                { title = Title.default "date"
                , variable = \x -> x.createdate |> toFloat |> Just
                , pixels = round dimension.height
                , range = Range.default
                , axisLine = AxisLine.default
                , ticks = Ticks.default
                }
        , y =
            Axis.custom
                { title = Title.default "value"
                , variable = \x -> x.value |> Just
                , pixels = round dimension.width
                , range = Range.default
                , axisLine = AxisLine.default
                , ticks = Ticks.default
                }
        , container = Container.styled "line-chart-1" [ ( "font-family", "monospace" ) ]
        , interpolation = Interpolation.default
        , intersection = Intersection.default
        , legends = Legends.default
        , events = Events.default
        , junk = Junk.default
        , grid = Grid.default
        , area = Area.default
        , line = Line.default
        , dots = Dots.default
        }
        [ LineChart.line Colors.rust Dots.circle "Measurements" measurements
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
