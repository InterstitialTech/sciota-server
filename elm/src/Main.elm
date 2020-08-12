module Main exposing (main)

-- import PublicInterface as PI

import BadError
import Browser
import Browser.Navigation
import Cellme.Cellme exposing (Cell, CellContainer(..), CellState, RunState(..), evalCellsFully, evalCellsOnce)
import Cellme.DictCellme exposing (CellDict(..), DictCell, dictCcr, getCd, mkCc)
import Data
import Dict exposing (Dict)
import EditDevice
import EditDeviceListing
import EditSensor
import Element exposing (Element)
import Element.Background as EBk
import Element.Border as EBd
import Element.Font as Font
import Element.Input as EI
import Element.Region
import Html exposing (Attribute, Html)
import Html.Attributes
import Http
import Login
import Markdown.Block as Block exposing (Block, Inline, ListItem(..), Task(..))
import Markdown.Html
import Markdown.Parser
import Markdown.Renderer
import Random exposing (Seed, initialSeed)
import Schelme.Show exposing (showTerm)
import ShowMessage
import Url exposing (Url)
import Url.Parser as UP exposing ((</>))
import UserInterface as UI
import Util
import ViewMeasurements


type Msg
    = LoginMsg Login.Msg
    | BadErrorMsg BadError.Msg
    | EditDeviceMsg EditDevice.Msg
    | EditDeviceListingMsg EditDeviceListing.Msg
    | EditSensorMsg EditSensor.Msg
    | ViewMeasurementsMsg ViewMeasurements.Msg
      -- | EditSensorListingMsg EditSensorListing.Msg
    | ShowMessageMsg ShowMessage.Msg
    | UserReplyData (Result Http.Error UI.ServerResponse)
      -- | PublicReplyData (Result Http.Error PI.ServerResponse)
    | LoadUrl String
    | InternalUrl Url
    | Noop


type WaitMode
    = WmDevice Data.Device (Data.Device -> List Data.Sensor -> State)
    | WmMeasurements (List Data.Measurement -> State)



-- | WmDevicel (List Data.Sensor) Data.Device
-- | WmDevicelm (Maybe (List Data.DeviceListNote)) (Maybe Data.FullSensor) Data.Device (List Data.DeviceListNote -> Data.FullSensor -> Data.Device -> State)


type State
    = Login Login.Model
    | EditDevice EditDevice.Model Data.Login
    | EditDeviceListing EditDeviceListing.Model Data.Login
    | EditSensor EditSensor.Model Data.Login (Maybe Data.Sensor -> State)
      -- | EditSensorListing EditSensorListing.Model Data.Login
    | BadError BadError.Model State
    | ShowMessage ShowMessage.Model Data.Login
    | PubShowMessage ShowMessage.Model
    | ViewMeasurements ViewMeasurements.Model State
    | Wait State WaitMode


type alias Flags =
    { seed : Int
    , location : String
    , useragent : String
    , debugstring : String
    , width : Int
    , height : Int
    }


type alias Model =
    { state : State
    , size : Util.Size
    , location : String
    , navkey : Browser.Navigation.Key
    , seed : Seed
    }


stateLogin : State -> Maybe Data.Login
stateLogin state =
    case state of
        Login lmod ->
            Just { uid = lmod.userId, pwd = lmod.password }

        EditDevice _ login ->
            Just login

        EditDeviceListing _ login ->
            Just login

        EditSensor _ login _ ->
            Just login

        ViewMeasurements _ s ->
            stateLogin s

        -- EditSensorListing _ login ->
        --     Just login
        BadError _ bestate ->
            stateLogin bestate

        ShowMessage _ login ->
            Just login

        PubShowMessage _ ->
            Nothing

        Wait bwstate _ ->
            stateLogin bwstate


viewState : Util.Size -> State -> Element Msg
viewState size state =
    case state of
        Login lem ->
            Element.map LoginMsg <| Login.view size lem

        EditDeviceListing em _ ->
            Element.map EditDeviceListingMsg <| EditDeviceListing.view em

        EditSensor em _ _ ->
            Element.map EditSensorMsg <| EditSensor.view em

        ViewMeasurements m _ ->
            Element.map ViewMeasurementsMsg <| ViewMeasurements.view m

        -- EditSensorListing em _ ->
        --     Element.map EditSensorListingMsg <| EditSensorListing.view em
        ShowMessage em _ ->
            Element.map ShowMessageMsg <| ShowMessage.view em

        PubShowMessage em ->
            Element.map ShowMessageMsg <| ShowMessage.view em

        EditDevice em _ ->
            Element.map EditDeviceMsg <| EditDevice.view em

        BadError em _ ->
            Element.map BadErrorMsg <| BadError.view em

        Wait innerState _ ->
            Element.map (\_ -> Noop) (viewState size innerState)


view : Model -> { title : String, body : List (Html Msg) }
view model =
    { title = "measure log"
    , body =
        [ Element.layout [] <|
            viewState model.size model.state
        ]
    }


sendUIMsg : String -> Data.Login -> UI.SendMsg -> Cmd Msg
sendUIMsg location login msg =
    Http.post
        { url = location ++ "/user"
        , body =
            Http.jsonBody
                (UI.encodeSendMsg msg
                    login.uid
                    login.pwd
                )
        , expect = Http.expectJson UserReplyData UI.serverResponseDecoder
        }



-- sendPIMsg : String -> PI.SendMsg -> Cmd Msg
-- sendPIMsg location msg =
--     Http.post
--         { url = location ++ "/public"
--         , body =
--             Http.jsonBody
--                 (PI.encodeSendMsg msg)
--         , expect = Http.expectJson PublicReplyData PI.serverResponseDecoder
--         }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( msg, model.state ) of
        ( InternalUrl url, _ ) ->
            let
                mblogin =
                    stateLogin model.state

                ( state, cmd ) =
                    parseUrl url
                        |> Maybe.map
                            (routeState model.location model.seed)
                        |> Maybe.withDefault ( model.state, Cmd.none )
            in
            ( { model | state = state }, cmd )

        ( LoginMsg lm, Login ls ) ->
            let
                ( lmod, lcmd ) =
                    Login.update lm ls
            in
            case lcmd of
                Login.None ->
                    ( { model | state = Login lmod }, Cmd.none )

                Login.Register ->
                    ( { model | state = Login lmod }
                    , sendUIMsg model.location
                        { uid =
                            lmod.userId
                        , pwd =
                            lmod.password
                        }
                        (UI.Register ls.email)
                    )

                Login.Login ->
                    ( { model | state = Login lmod }
                    , sendUIMsg model.location
                        { uid =
                            lmod.userId
                        , pwd =
                            lmod.password
                        }
                        UI.Login
                    )

        -- ( PublicReplyData prd, state ) ->
        --     case prd of
        --         Err e ->
        --             ( { model | state = BadError (BadError.initialModel <| Util.httpErrorString e) model.state }, Cmd.none )
        --         Ok piresponse ->
        --             case piresponse of
        --                 PI.ServerError e ->
        --                     ( { model | state = BadError (BadError.initialModel e) state }, Cmd.none )
        --                 PI.Sensor fbe ->
        --                     ( { model | state = View (View.initFull fbe) }, Cmd.none )
        ( UserReplyData urd, state ) ->
            case urd of
                Err e ->
                    ( { model | state = BadError (BadError.initialModel <| Util.httpErrorString e) model.state }, Cmd.none )

                Ok uiresponse ->
                    case uiresponse of
                        UI.ServerError e ->
                            ( { model | state = BadError (BadError.initialModel e) state }, Cmd.none )

                        UI.RegistrationSent ->
                            ( model, Cmd.none )

                        UI.LoggedIn ->
                            case state of
                                Login lmod ->
                                    -- we're logged in!  Get article listing.
                                    ( { model
                                        | state =
                                            ShowMessage
                                                { message = "loading articles"
                                                }
                                                { uid = lmod.userId, pwd = lmod.password }
                                        , seed = lmod.seed -- save the seed!
                                      }
                                    , sendUIMsg model.location
                                        { uid =
                                            lmod.userId
                                        , pwd =
                                            lmod.password
                                        }
                                        UI.GetDeviceListing
                                    )

                                _ ->
                                    ( { model | state = BadError (BadError.initialModel "unexpected login reply") state }
                                    , Cmd.none
                                    )

                        UI.Device d ->
                            ( model, Cmd.none )

                        UI.MeasurementListing l ->
                            case model.state of
                                Wait st (WmMeasurements sfn) ->
                                    ( { model | state = sfn l }, Cmd.none )

                                _ ->
                                    ( { model
                                        | state =
                                            BadError (BadError.initialModel "was expecting measurements!") state
                                      }
                                    , Cmd.none
                                    )

                        UI.Measurement m ->
                            ( model, Cmd.none )

                        UI.DeviceListing l ->
                            case state of
                                ShowMessage _ login ->
                                    ( { model | state = EditDeviceListing { devices = l } login }, Cmd.none )

                                _ ->
                                    ( { model | state = BadError (BadError.initialModel "unexpected login reply") state }
                                    , Cmd.none
                                    )

                        UI.SensorListing l ->
                            case state of
                                Wait zwstate wm ->
                                    case ( wm, stateLogin zwstate ) of
                                        ( WmDevice device statefn, Just login ) ->
                                            ( { model | state = statefn device l }
                                            , Cmd.none
                                            )

                                        -- ( WmDevicel Nothing mbzkn zk tostate, Just login ) ->
                                        --     case mbzkn of
                                        --         Just zkn ->
                                        --             ( { model | state = tostate l zkn zk }
                                        --             , Cmd.none
                                        --             )
                                        --         Nothing ->
                                        --             ( { model | state = Wait zwstate (WmDevicelm (Just l) mbzkn zk tostate) }, Cmd.none )
                                        _ ->
                                            ( { model | state = BadError (BadError.initialModel "unexpected reply") state }
                                            , Cmd.none
                                            )

                                _ ->
                                    ( { model | state = BadError (BadError.initialModel "unexpected zknote listing") state }
                                    , Cmd.none
                                    )

                        UI.Sensor zkn ->
                            case state of
                                EditDeviceListing _ login ->
                                    -- ( { model | state = EditSensor (EditSensor.initFull zkn) login }, Cmd.none )
                                    ( { model | state = BadError (BadError.initialModel "zknoteeditunimplmeented") state }
                                    , Cmd.none
                                    )

                                Wait bwstate mode ->
                                    case mode of
                                        WmDevice _ _ ->
                                            ( { model | state = BadError (BadError.initialModel "can't edit - no zklist!") state }, Cmd.none )

                                        WmMeasurements _ ->
                                            ( { model | state = BadError (BadError.initialModel "unexpected sensor record!") state }, Cmd.none )

                                -- WmDevicel sensors device ->
                                --     case stateLogin state of
                                --         Just login ->
                                --             ( { model | state = EditSensor (EditSensor.init zk zkl zkn) login }, Cmd.none )
                                --         Nothing ->
                                --             ( { model | state = BadError (BadError.initialModel "can't edit - not logged in!") state }, Cmd.none )
                                -- ( { model | state = BadError (BadError.initialModel "unexpected message") bwstate }, Cmd.none )
                                _ ->
                                    ( { model | state = BadError (BadError.initialModel "unexpected blog message") state }, Cmd.none )

                        UI.DeviceSaved beid ->
                            case state of
                                EditDevice emod login ->
                                    ( { model | state = EditDevice (EditDevice.setId emod beid) login }, Cmd.none )

                                _ ->
                                    ( { model | state = BadError (BadError.initialModel "unexpected blog message") state }, Cmd.none )

                        UI.DeviceDeleted beid ->
                            case state of
                                ShowMessage _ login ->
                                    ( model
                                    , sendUIMsg model.location login UI.GetDeviceListing
                                    )

                                _ ->
                                    ( { model | state = BadError (BadError.initialModel "unexpected message") state }, Cmd.none )

                        UI.SensorSaved sensor ->
                            case state of
                                EditSensor emod login tostate ->
                                    ( { model | state = tostate (Just sensor) }
                                    , Cmd.none
                                    )

                                _ ->
                                    ( { model | state = BadError (BadError.initialModel "unexpected blog message") state }, Cmd.none )

                        UI.SensorDeleted beid ->
                            ( model, Cmd.none )

                        -- case state of
                        --     ShowMessage _ login ->
                        --         ( model
                        --         , sendUIMsg model.location login UI.GetSensorListing
                        --         )
                        --     _ ->
                        --         ( { model | state = BadError (BadError.initialModel "unexpected message") state }, Cmd.none )
                        UI.UserExists ->
                            ( { model | state = BadError (BadError.initialModel "Can't register - User exists already!") state }, Cmd.none )

                        UI.UnregisteredUser ->
                            ( { model | state = BadError (BadError.initialModel "Unregistered user.  Check your spam folder!") state }, Cmd.none )

                        UI.InvalidUserOrPwd ->
                            ( { model | state = BadError (BadError.initialModel "Invalid username or password.") state }, Cmd.none )

        ( EditDeviceMsg em, EditDevice es login ) ->
            let
                ( emod, ecmd ) =
                    EditDevice.update em es
            in
            case ecmd of
                EditDevice.Save zk ->
                    ( { model | state = EditDevice emod login }
                    , sendUIMsg model.location
                        login
                        (UI.SaveDevice zk)
                    )

                EditDevice.None ->
                    ( { model | state = EditDevice emod login }, Cmd.none )

                EditDevice.Done ->
                    ( { model
                        | state =
                            ShowMessage
                                { message = "loading articles"
                                }
                                login
                      }
                    , sendUIMsg model.location
                        login
                        UI.GetDeviceListing
                    )

                EditDevice.Delete id ->
                    -- issue delete and go back to listing.
                    ( { model
                        | state =
                            ShowMessage
                                { message = "loading articles"
                                }
                                login
                      }
                    , sendUIMsg model.location
                        login
                        (UI.DeleteDevice id)
                    )

                EditDevice.View sbe ->
                    ( { model | state = BadError (BadError.initialModel "EditDevice.View sbe -> unimplmeented") model.state }
                    , Cmd.none
                    )

                EditDevice.NewSensor deviceid ->
                    let
                        _ =
                            Debug.log "newsensors" ""
                    in
                    ( { model
                        | state =
                            EditSensor
                                (EditSensor.initNew deviceid)
                                login
                                (\mbsensor ->
                                    case mbsensor of
                                        Just sensor ->
                                            EditDevice (EditDevice.setSensor sensor es) login

                                        Nothing ->
                                            EditDevice es login
                                )
                      }
                    , Cmd.none
                    )

                EditDevice.EditSensor sensor ->
                    ( { model
                        | state =
                            EditSensor
                                (EditSensor.init sensor)
                                login
                                (\mbsensor ->
                                    case mbsensor of
                                        Just s ->
                                            EditDevice (EditDevice.setSensor s es) login

                                        Nothing ->
                                            EditDevice es login
                                )
                      }
                    , Cmd.none
                    )

                EditDevice.ViewSensorMeasurements sensor ->
                    ( { model
                        | state =
                            Wait
                                (ShowMessage
                                    { message = "loading articles"
                                    }
                                    login
                                )
                                (WmMeasurements
                                    (\measurements ->
                                        ViewMeasurements
                                            { id = sensor.id
                                            , name = sensor.name
                                            , values = measurements
                                            }
                                            model.state
                                    )
                                )
                      }
                    , sendUIMsg model.location
                        login
                        (UI.GetMeasurementListing
                            { sensor = sensor.id
                            , enddate = Nothing
                            , lengthOfTime = Nothing
                            }
                        )
                    )

        ( EditSensorMsg em, EditSensor es login esstate ) ->
            let
                ( emod, ecmd ) =
                    EditSensor.update em es
            in
            case ecmd of
                EditSensor.Save zk ->
                    ( { model | state = EditSensor emod login esstate }
                    , sendUIMsg model.location
                        login
                        (UI.SaveSensor zk)
                    )

                EditSensor.None ->
                    ( { model | state = EditSensor emod login esstate }, Cmd.none )

                EditSensor.Cancel ->
                    ( { model
                        | state = esstate Nothing
                      }
                    , Cmd.none
                    )

        ( ViewMeasurementsMsg em, ViewMeasurements es esstate ) ->
            let
                ( emod, ecmd ) =
                    ViewMeasurements.update em es
            in
            case ecmd of
                ViewMeasurements.None ->
                    ( { model | state = ViewMeasurements emod esstate }, Cmd.none )

                ViewMeasurements.Done ->
                    ( { model
                        | state = esstate
                      }
                    , Cmd.none
                    )

        ( EditDeviceListingMsg em, EditDeviceListing es login ) ->
            let
                ( emod, ecmd ) =
                    EditDeviceListing.update em es
            in
            case ecmd of
                EditDeviceListing.New ->
                    ( { model | state = EditDevice EditDevice.initNew login }, Cmd.none )

                EditDeviceListing.Selected device ->
                    ( { model
                        | state =
                            Wait
                                (ShowMessage
                                    { message = "loading device"
                                    }
                                    login
                                )
                                (WmDevice device
                                    (\d listing ->
                                        EditDevice (EditDevice.init d listing) login
                                    )
                                )
                      }
                    , sendUIMsg model.location
                        login
                        (UI.GetSensorListing <| Just device.id)
                    )

        ( BadErrorMsg bm, BadError bs prevstate ) ->
            let
                ( bmod, bcmd ) =
                    BadError.update bm bs
            in
            case bcmd of
                BadError.Okay ->
                    ( { model | state = prevstate }, Cmd.none )

        ( _, _ ) ->
            ( model, Cmd.none )


init : Flags -> Url -> Browser.Navigation.Key -> ( Model, Cmd Msg )
init flags url key =
    let
        _ =
            Debug.log "parsed: " (parseUrl url)

        seed =
            initialSeed (flags.seed + 7)

        ( state, cmd ) =
            parseUrl url
                |> Maybe.map (routeState flags.location seed)
                |> Maybe.withDefault ( initLogin seed, Cmd.none )
    in
    ( { state = state
      , size = { width = flags.width, height = flags.height }
      , location = flags.location
      , navkey = key
      , seed = seed
      }
    , cmd
    )


type Route
    = PublicDevice Int
    | Fail


parseUrl : Url -> Maybe Route
parseUrl url =
    UP.parse
        (UP.map (\i -> PublicDevice i) <|
            UP.s
                "blog"
                </> UP.int
        )
        url


initLogin : Seed -> State
initLogin seed =
    Login <| Login.initialModel Nothing "mahbloag" seed


routeState : String -> Seed -> Route -> ( State, Cmd Msg )
routeState location seed route =
    -- case route of
    --     PublicDevice id ->
    --         ( PubShowMessage
    --             { message = "loading article"
    --             }
    --         , sendPIMsg location
    --             (PI.GetSensor id)
    --         )
    --     Fail ->
    --         ( initLogin seed, Cmd.none )
    ( initLogin seed, Cmd.none )


urlRequest : Browser.UrlRequest -> Msg
urlRequest ur =
    let
        _ =
            Debug.log "ur: " ur
    in
    case ur of
        Browser.Internal url ->
            InternalUrl url

        Browser.External str ->
            LoadUrl str


main : Platform.Program Flags Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = \model -> Sub.none
        , onUrlRequest = urlRequest
        , onUrlChange =
            \uc ->
                let
                    _ =
                        Debug.log "uc: " uc
                in
                Noop

        -- Url -> msg
        }
