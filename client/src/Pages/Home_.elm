module Pages.Home_ exposing (Model, Msg, page)

import Gen.Params.Home_ exposing (Params)
import Page
import Request
import Shared
import UI.Layout.Header
import UI.Layout.Template
import View exposing (View)


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page _ req =
    Page.element
        { init = init req
        , update = update
        , view = view
        , subscriptions = always Sub.none
        }


type alias Model =
    { header : UI.Layout.Header.Model }


init : Request.With Params -> ( Model, Cmd Msg )
init req =
    ( { header = UI.Layout.Header.init req }, Cmd.none )


type Msg
    = FromHeader UI.Layout.Header.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        FromHeader subMsg ->
            UI.Layout.Header.update subMsg model.header
                |> Tuple.mapFirst (\newHeader -> { model | header = newHeader })


view : Model -> View Msg
view _ =
    UI.Layout.Template.view FromHeader []
