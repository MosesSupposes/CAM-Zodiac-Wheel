port module Main exposing (main)

import Browser
import Html exposing (Html, text)
import Json.Decode as Decode


port dragEvents : (Decode.Value -> msg) -> Sub msg


type Action server user
    = ServerAction server
    | UserAction user


type UserAction
    = Click
    | Drag DragPayload
    | Exit
    | Resize
    | Filter FilterBy
    | NoOp


type FilterBy
    = FilterByDate String
    | FilterByElement String
    | FilterByPlanet String
    | FilterBySign String
    | FilterByRelationship String
    | FilterByCustom String


type alias DragPayload =
    { rotation : Float
    , delta : Float
    , radius : Float
    }


type alias Model =
    { lastAction : Action () UserAction
    }


type Msg
    = ReceiveEvent Decode.Value


main : Program () Model Msg
main =
    Browser.element
        { init = \_ -> ( { lastAction = UserAction NoOp }, Cmd.none )
        , update = update
        , subscriptions = subscriptions
        , view = view
        }


subscriptions : Model -> Sub Msg
subscriptions _ =
    dragEvents ReceiveEvent


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ReceiveEvent payload ->
            case Decode.decodeValue eventDecoder payload of
                Ok action ->
                    ( { model | lastAction = action }, Cmd.none )

                Err _ ->
                    ( model, Cmd.none )


view : Model -> Html Msg
view _ =
    text ""


eventDecoder : Decode.Decoder (Action () UserAction)
eventDecoder =
    Decode.oneOf
        [ Decode.map (UserAction << Filter) filterDecoder
        , Decode.map (UserAction << Drag) (Decode.field "drag" dragDecoder)
        ]


dragDecoder : Decode.Decoder DragPayload
dragDecoder =
    Decode.map3 DragPayload
        (Decode.field "rotation" Decode.float)
        (Decode.field "delta" Decode.float)
        (Decode.field "radius" Decode.float)


filterDecoder : Decode.Decoder FilterBy
filterDecoder =
    Decode.field "filterBy" Decode.string
        |> Decode.andThen
            (\filterName ->
                Decode.field "value" Decode.string
                    |> Decode.map
                        (\value ->
                            case filterName of
                                "date" ->
                                    FilterByDate value

                                "element" ->
                                    FilterByElement value

                                "planet" ->
                                    FilterByPlanet value

                                "sign" ->
                                    FilterBySign value

                                "relationship" ->
                                    FilterByRelationship value

                                _ ->
                                    FilterByCustom value
                        )
            )
