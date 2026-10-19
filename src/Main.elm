port module Main exposing (main)

import Browser
import Html exposing (Html, a, article, button, div, h1, h2, h3, p, section, span, text)
import Html.Attributes exposing (attribute, class, href, style)
import Html.Events exposing (onClick)
import Json.Decode as Decode


type Mode
    = Launcher
    | Details


type Tab
    = Overview
    | Elements
    | Insights
    | Transits
    | Horoscope
    | Pricing


type alias Placement =
    { name : String
    , longitude : Float
    , house : Int
    }


type alias Chart =
    { name : String
    , houseSystem : String
    , zodiacMode : String
    , ascendant : Float
    , cusps : List Float
    , placements : List Placement
    }


type alias Aspect =
    { first : Placement
    , second : Placement
    , name : String
    , glyph : String
    , exactAngle : Float
    , orb : Float
    }


type alias Model =
    { mode : Mode
    , chart : Maybe Chart
    , tab : Tab
    , moreOpen : Bool
    }


type Msg
    = SelectTab Tab
    | OpenDetails
    | ToggleMore


port openDetailsPage : String -> Cmd msg


main : Program Decode.Value Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = always Sub.none
        , view = view
        }


init : Decode.Value -> ( Model, Cmd Msg )
init flags =
    let
        mode =
            Decode.decodeValue (Decode.field "mode" Decode.string) flags
                |> Result.withDefault "launcher"
                |> (\value ->
                        if value == "details" then
                            Details

                        else
                            Launcher
                   )

        maybeChart =
            Decode.decodeValue (Decode.field "chart" chartDecoder) flags
                |> Result.toMaybe
    in
    ( { mode = mode, chart = maybeChart, tab = Overview, moreOpen = False }, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SelectTab tab ->
            ( { model | tab = tab, moreOpen = False }, Cmd.none )

        OpenDetails ->
            ( model, openDetailsPage "./chart-insights.html" )

        ToggleMore ->
            ( { model | moreOpen = not model.moreOpen }, Cmd.none )


view : Model -> Html Msg
view model =
    case model.mode of
        Launcher ->
            button
                [ class "insights-launcher"
                , attribute "aria-label" "Open your full chart insights"
                , onClick OpenDetails
                ]
                [ span [ class "insights-launcher-mark", attribute "aria-hidden" "true" ] [ text "✦" ]
                , span [] [ text "Explore my chart" ]
                , span [ class "insights-launcher-arrow", attribute "aria-hidden" "true" ] [ text "↗" ]
                ]

        Details ->
            detailsView model


detailsView : Model -> Html Msg
detailsView model =
    div [ class "chart-details-app" ]
        [ a [ class "details-back", href "./Your%20zodiac%20wheel.html" ] [ text "← Back to the wheel" ]
        , case model.chart of
            Just chart ->
                div []
                    [ section [ class "details-heading" ]
                        [ p [ class "details-kicker" ] [ text (chart.houseSystem ++ " · " ++ chart.zodiacMode) ]
                        , h1 [] [ text (welcome chart.name) ]
                        , p [ class "details-summary" ]
                            [ text (signName chart.ascendant ++ " rising · " ++ signElement chart.ascendant ++ " Ascendant") ]
                        ]
                    , navigation model.tab
                    , moreMenu model
                    , section [ class "details-content", attribute "aria-live" "polite" ]
                        [ tabContent chart model.tab ]
                    ]

            Nothing ->
                section [ class "details-empty" ]
                    [ p [ class "details-kicker" ] [ text "Your chart is waiting" ]
                    , h1 [] [ text "Start with your birth details" ]
                    , p [] [ text "Calculate your chart on the wheel first. Your sign, element, and house placements will appear here." ]
                    , a [ class "details-primary", href "./Your%20zodiac%20wheel.html" ] [ text "Open the zodiac wheel" ]
                    ]
        ]


navigation : Tab -> Html Msg
navigation activeTab =
    let
        tabs =
            [ ( Overview, "Overview" )
            , ( Elements, "Elements" )
            , ( Insights, "Key insights" )
            , ( Transits, "Transits" )
            , ( Horoscope, "Horoscope" )
            ]
    in
    div [ class "details-tabs", attribute "role" "tablist", attribute "aria-label" "Chart information" ]
        (List.map (tabButton activeTab) tabs)


moreMenu : Model -> Html Msg
moreMenu model =
    div [ class "details-more" ]
        [ button
            [ class (if model.tab == Pricing then "details-more-toggle is-active" else "details-more-toggle")
            , onClick ToggleMore
            , attribute "aria-expanded" (if model.moreOpen then "true" else "false")
            ]
            [ text "More" ]
        , if model.moreOpen then
            div [ class "details-more-menu" ]
                [ button
                    [ class (if model.tab == Pricing then "details-more-item is-active" else "details-more-item")
                    , onClick (SelectTab Pricing)
                    ]
                    [ text "Pricing" ]
                ]

          else
            text ""
        ]


tabButton : Tab -> ( Tab, String ) -> Html Msg
tabButton activeTab ( tab, label ) =
    button
        [ class (if tab == activeTab then "details-tab is-active" else "details-tab")
        , attribute "role" "tab"
        , attribute "aria-selected" (if tab == activeTab then "true" else "false")
        , onClick (SelectTab tab)
        ]
        [ text label ]


tabContent : Chart -> Tab -> Html Msg
tabContent chart tab =
    case tab of
        Overview ->
            overviewTab chart

        Elements ->
            elementsTab chart

        Insights ->
            insightsTab chart

        Transits ->
            section [ class "details-section" ]
                [ p [ class "details-kicker" ] [ text "Transits" ]
                , h2 [] [ text "Current planetary movement" ]
                , p [ class "details-muted" ] [ text "Transit calculations are not available yet." ]
                ]

        Horoscope ->
            section [ class "details-section", attribute "aria-label" "Horoscope" ] []

        Pricing ->
            section [ class "details-section", attribute "aria-label" "Pricing" ] []


overviewTab : Chart -> Html Msg
overviewTab chart =
    section [ class "details-section" ]
        [ div [ class "overview-lead" ]
            [ div []
                [ p [ class "details-kicker" ] [ text "Your chart at a glance" ]
                , h2 [] [ text "A map of your sky" ]
                , p [ class "details-muted" ] [ text (signName chart.ascendant ++ " anchors the horizon. Explore the placements and house doors below.") ]
                ]
            , div [ class "overview-stats" ]
                [ overviewStat (String.fromInt (List.length chart.placements)) "placements"
                , overviewStat (String.fromInt (List.length (chartAspects chart.placements))) "major aspects"
                ]
            ]
        , div [ class "overview-placement-grid" ] (List.map placementCard chart.placements)
        , houseMap chart
        , div [ class "cusp-summary" ]
            [ h3 [] [ text "House doors" ]
            , div [ class "cusp-grid" ] (List.indexedMap cuspCard chart.cusps)
            ]
        ]


elementsTab : Chart -> Html Msg
elementsTab chart =
    let
        data =
            elementData chart.placements

        maxCount =
            List.map (Tuple.second >> List.length) data |> List.maximum |> Maybe.withDefault 0

        strongest =
            data
                |> List.filter (\( _, placements ) -> List.length placements == maxCount && maxCount > 0)
                |> List.map Tuple.first

        absent =
            data
                |> List.filter (\( _, placements ) -> List.isEmpty placements)
                |> List.map Tuple.first

        summary =
            if maxCount == 0 then
                "No planetary placements are available to compare yet."

            else if List.length strongest == 4 then
                "Your sampled placements are evenly spread across the four elements."

            else
                String.join " · " strongest
                    ++ (if List.length strongest == 1 then " leads" else " share the lead")
                    ++ " in this three-point snapshot."
    in
    section [ class "details-section" ]
        [ div [ class "elements-heading" ]
            [ div []
                [ p [ class "details-kicker" ] [ text "Elements · chart balance" ]
                , h2 [] [ text "Four forces, one chart" ]
                , p [ class "details-muted" ] [ text "A quick read of your calculated Sun, Moon, and Lilith signs." ]
                ]
            , div [ class "element-total" ]
                [ span [ class "element-total-value" ] [ text (String.fromInt (List.length chart.placements)) ]
                , span [ class "element-total-label" ] [ text "placements" ]
                ]
            ]
        , div [ class "element-orbit" ]
            (List.map (elementCard maxCount) data)
        , section [ class "element-reading" ]
            [ p [ class "details-kicker" ] [ text "Reading the balance" ]
            , h3 [] [ text summary ]
            , p [ class "details-muted" ]
                [ text
                    (if List.isEmpty absent then
                        "All four elements appear in these placements."

                     else
                        "Not represented in these placements: " ++ String.join " · " absent ++ "."
                    )
                ]
            ]
        , p [ class "element-note" ]
            [ text "This tally includes three placements only; it is a visual guide, not a full chart-wide element count." ]
        ]


insightsTab : Chart -> Html Msg
insightsTab chart =
    let
        rising = signName chart.ascendant
        risingElement = signElement chart.ascendant

        houseThemes =
            List.indexedMap Tuple.pair chart.cusps
                |> List.filterMap
                    (\( index, cusp ) ->
                        List.filter (\placement -> placement.house == index + 1) chart.placements
                            |> List.head
                            |> Maybe.map (\placement -> { house = index + 1, cusp = cusp, placement = placement })
                    )

        aspects =
            chartAspects chart.placements
    in
    section [ class "details-section" ]
        [ div [ class "insight-hero" ]
            [ span [ class "insight-hero-glyph", attribute "aria-hidden" "true" ] [ text (signGlyph chart.ascendant) ]
            , div []
                [ p [ class "details-kicker" ] [ text "Key insights · first look" ]
                , h2 [] [ text (rising ++ " rising") ]
                , p [ class "details-muted" ] [ text (risingElement ++ " at the Ascendant sets the tone of the chart's horizon.") ]
                ]
            ]
        , section [ class "insight-block" ]
            [ div [ class "insight-block-heading" ]
                [ span [ class "insight-index" ] [ text "01" ]
                , div [] [ p [ class "details-kicker" ] [ text "House stories" ], h3 [] [ text "Where the planets gather" ] ]
                ]
            , if List.isEmpty houseThemes then
                p [ class "details-muted" ] [ text "No major placements have been assigned to houses yet." ]

              else
                div [ class "house-insight-list" ] (List.map houseInsight houseThemes)
            ]
        , section [ class "insight-block aspect-block" ]
            [ div [ class "insight-block-heading" ]
                [ span [ class "insight-index" ] [ text "02" ]
                , div [] [ p [ class "details-kicker" ] [ text "Major aspects · 8° orb" ], h3 [] [ text "The dialogue between placements" ] ]
                ]
            , if List.isEmpty aspects then
                p [ class "details-muted" ] [ text "No major aspects fall within the selected orb for these placements." ]

              else
                div [ class "aspect-list" ] (List.map aspectCard aspects)
            ]
        ]


overviewStat : String -> String -> Html Msg
overviewStat value label =
    div [ class "overview-stat" ]
        [ span [ class "overview-stat-value" ] [ text value ]
        , span [ class "overview-stat-label" ] [ text label ]
        ]


placementCard : Placement -> Html Msg
placementCard placement =
    let
        element =
            String.toLower (signElement placement.longitude)
    in
    article [ class ("overview-placement-card element-" ++ element) ]
        [ div [ class "overview-placement-mark" ] [ text (signGlyph placement.longitude) ]
        , div [ class "overview-placement-copy" ]
            [ p [ class "overview-placement-name" ] [ text placement.name ]
            , h3 [] [ text (signName placement.longitude) ]
            , p [ class "overview-placement-meta" ] [ text (formatLongitude placement.longitude) ]
            ]
        , div [ class "overview-house-chip" ] [ text ("H" ++ String.fromInt placement.house) ]
        ]


houseMap : Chart -> Html Msg
houseMap chart =
    div [ class "house-map" ]
        [ div [ class "house-map-center" ]
            [ span [ class "house-map-glyph" ] [ text (signGlyph chart.ascendant) ]
            , span [ class "house-map-center-label" ] [ text "ASC" ]
            , span [ class "house-map-center-sign" ] [ text (signName chart.ascendant) ]
            ]
        , div [ class "house-map-ring" ]
            (List.indexedMap houseMapMarker chart.cusps)
        ]


houseMapMarker : Int -> Float -> Html Msg
houseMapMarker index cusp =
    let
        angle =
            toFloat index * 30 - 90
    in
    div
        [ class "house-map-marker"
        , style "--marker-angle" (String.fromFloat angle ++ "deg")
        , style "--marker-index" (String.fromInt index)
        ]
        [ span [ class "house-map-marker-number" ] [ text (String.fromInt (index + 1)) ]
        , span [ class "house-map-marker-sign" ] [ text (signGlyph cusp) ]
        ]


cuspCard : Int -> Float -> Html Msg
cuspCard index cusp =
    div [ class "cusp-card" ]
        [ span [ class "cusp-card-number" ] [ text ("H" ++ String.fromInt (index + 1)) ]
        , span [ class "cusp-card-glyph" ] [ text (signGlyph cusp) ]
        , span [ class "cusp-card-sign" ] [ text (signName cusp) ]
        ]


houseInsight : { house : Int, cusp : Float, placement : Placement } -> Html Msg
houseInsight entry =
    article [ class "house-insight" ]
        [ div [ class "house-insight-heading" ]
            [ span [ class "house-insight-glyph" ] [ text (signGlyph entry.cusp) ]
            , div []
                [ p [ class "house-insight-overline" ] [ text ("HOUSE " ++ String.fromInt entry.house ++ " · " ++ houseName entry.house) ]
                , h3 [] [ text (entry.placement.name ++ " in " ++ signName entry.placement.longitude) ]
                ]
            ]
        , p [] [ text (houseInsightCopy entry.placement.name entry.house) ]
        , span [ class "house-insight-cusp" ] [ text ("Cusp " ++ formatLongitude entry.cusp) ]
        ]


aspectCard : Aspect -> Html Msg
aspectCard aspect =
    article [ class "aspect-card" ]
        [ div [ class "aspect-pair" ]
            [ span [ class "aspect-planet" ] [ text (placementGlyph aspect.first.name) ]
            , span [ class "aspect-symbol" ] [ text aspect.glyph ]
            , span [ class "aspect-planet" ] [ text (placementGlyph aspect.second.name) ]
            ]
        , div [ class "aspect-copy" ]
            [ h3 [] [ text (aspect.first.name ++ " " ++ aspect.name ++ " " ++ aspect.second.name) ]
            , p [] [ text (signName aspect.first.longitude ++ " and " ++ signName aspect.second.longitude ++ " · " ++ formatLongitude aspect.orb ++ " orb") ]
            ]
        ]


chartAspects : List Placement -> List Aspect
chartAspects placements =
    let
        pairs remaining =
            case remaining of
                first :: rest ->
                    List.map (Tuple.pair first) rest ++ pairs rest

                [] ->
                    []

        detect ( first, second ) =
            let
                rawDifference = abs (normalizeLongitude first.longitude - normalizeLongitude second.longitude)

                separation =
                    min rawDifference (360 - rawDifference)

                possibilities =
                    [ { name = "Conjunction", glyph = "☌", angle = 0, allowedOrb = 8 }
                    , { name = "Sextile", glyph = "⚹", angle = 60, allowedOrb = 5 }
                    , { name = "Square", glyph = "□", angle = 90, allowedOrb = 6 }
                    , { name = "Trine", glyph = "△", angle = 120, allowedOrb = 6 }
                    , { name = "Opposition", glyph = "☍", angle = 180, allowedOrb = 8 }
                    ]

                match =
                    possibilities
                        |> List.filterMap
                            (\aspect ->
                                let
                                    orb = abs (separation - aspect.angle)
                                in
                                if orb <= aspect.allowedOrb then
                                    Just { first = first, second = second, name = aspect.name, glyph = aspect.glyph, exactAngle = aspect.angle, orb = orb }

                                else
                                    Nothing
                            )
                        |> List.sortBy .orb
                        |> List.head
            in
            match
    in
    pairs placements |> List.filterMap detect |> List.sortBy .orb


elementData : List Placement -> List ( String, List Placement )
elementData placements =
    List.map
        (\element ->
            ( element
            , List.filter (\placement -> signElement placement.longitude == element) placements
            )
        )
        [ "Fire", "Earth", "Air", "Water" ]


elementCard : Int -> ( String, List Placement ) -> Html Msg
elementCard maxCount ( element, placements ) =
    let
        count =
            List.length placements

        percent =
            if maxCount == 0 then
                0

            else
                round (toFloat count / toFloat maxCount * 100)

        elementClass =
            "element-card element-" ++ String.toLower element

        glyph =
            case element of
                "Fire" ->
                    "△"

                "Earth" ->
                    "▽"

                "Air" ->
                    "✧"

                _ ->
                    "◒"
    in
    article [ class elementClass ]
        [ div [ class "element-card-heading" ]
            [ span [ class "element-glyph", attribute "aria-hidden" "true" ] [ text glyph ]
            , div [ class "element-card-title" ]
                [ h3 [] [ text element ]
                , p [] [ text (elementDescription element) ]
                ]
            , span [ class "element-count" ] [ text (String.fromInt count) ]
            ]
        , div [ class "element-meter", attribute "role" "meter", attribute "aria-valuemin" "0", attribute "aria-valuemax" (String.fromInt (max 1 maxCount)), attribute "aria-valuenow" (String.fromInt count), attribute "aria-label" (element ++ " placements") ]
            [ div [ class "element-meter-fill", style "width" (String.fromInt percent ++ "%") ] [] ]
        , div [ class "element-placement-list" ]
            (if List.isEmpty placements then
                [ span [ class "element-none" ] [ text "No placements" ] ]

             else
                List.map elementPlacement placements
            )
        ]


elementPlacement : Placement -> Html Msg
elementPlacement placement =
    span [ class "element-placement" ]
        [ text (placement.name ++ " · H" ++ String.fromInt placement.house) ]


elementDescription : String -> String
elementDescription element =
    case element of
        "Fire" ->
            "Drive · instinct · ignition"

        "Earth" ->
            "Ground · craft · continuity"

        "Air" ->
            "Thought · exchange · pattern"

        _ ->
            "Feeling · memory · flow"


insightRow : ( String, String ) -> Html Msg
insightRow ( title, description ) =
    div [ class "insight-row" ]
        [ h3 [] [ text title ]
        , p [] [ text description ]
        ]


cuspLabel : Int -> Float -> String
cuspLabel index longitude =
    "H" ++ String.fromInt (index + 1) ++ " " ++ signName longitude


findPlacement : String -> List Placement -> Maybe Placement
findPlacement name placements =
    List.filter (\placement -> placement.name == name) placements |> List.head


welcome : String -> String
welcome name =
    if String.trim name == "" then
        "Your chart, in fuller view"

    else
        "Your chart, " ++ String.trim name


signName : Float -> String
signName longitude =
    let
        index =
            modBy 12 (floor (normalizeLongitude longitude / 30))
    in
    Maybe.withDefault "Unknown" (List.drop index zodiacSigns |> List.head)


signGlyph : Float -> String
signGlyph longitude =
    let
        index = modBy 12 (floor (normalizeLongitude longitude / 30))
    in
    Maybe.withDefault "✦" (List.drop index zodiacGlyphs |> List.head)


placementGlyph : String -> String
placementGlyph name =
    case name of
        "Sun" ->
            "☉"

        "Moon" ->
            "☽"

        "Mean Lilith" ->
            "⚸"

        _ ->
            "✦"


houseName : Int -> String
houseName number =
    Maybe.withDefault "House" (List.drop (number - 1) houseNames |> List.head)


houseInsightCopy : String -> Int -> String
houseInsightCopy placement house =
    let
        area = houseName house
    in
    placement ++ " here brings a personal focus to " ++ String.toLower area ++ "."


signElement : Float -> String
signElement longitude =
    let
        signIndex = modBy 12 (floor (normalizeLongitude longitude / 30))
    in
    case modBy 4 signIndex of
        0 ->
            "Fire"

        1 ->
            "Earth"

        2 ->
            "Air"

        _ ->
            "Water"


formatLongitude : Float -> String
formatLongitude longitude =
    let
        withinSign = normalizeLongitude longitude - toFloat (floor (normalizeLongitude longitude / 30)) * 30

        degrees = floor withinSign

        minutes = floor ((withinSign - toFloat degrees) * 60)
    in
    String.fromInt degrees ++ "° " ++ String.padLeft 2 '0' (String.fromInt minutes) ++ "′ " ++ signName longitude


normalizeLongitude : Float -> Float
normalizeLongitude longitude =
    longitude - toFloat (floor (longitude / 360)) * 360


zodiacSigns : List String
zodiacSigns =
    [ "Aries", "Taurus", "Gemini", "Cancer", "Leo", "Virgo", "Libra", "Scorpio", "Sagittarius", "Capricorn", "Aquarius", "Pisces" ]


zodiacGlyphs : List String
zodiacGlyphs =
    [ "♈", "♉", "♊", "♋", "♌", "♍", "♎", "♏", "♐", "♑", "♒", "♓" ]


houseNames : List String
houseNames =
    [ "Self", "Worth", "Voice", "Roots", "Joy", "Craft", "Partnership", "Depth", "Horizons", "Legacy", "Community", "Solitude" ]


chartDecoder : Decode.Decoder Chart
chartDecoder =
    Decode.map6 Chart
        (Decode.oneOf [ Decode.field "name" Decode.string, Decode.succeed "" ])
        (Decode.field "houseSystem" Decode.string)
        (Decode.field "zodiacMode" Decode.string)
        (Decode.at [ "angles", "ascendant" ] Decode.float)
        (Decode.field "cusps" (Decode.list Decode.float))
        (Decode.field "placements" (Decode.list placementDecoder))


placementDecoder : Decode.Decoder Placement
placementDecoder =
    Decode.map3 Placement
        (Decode.field "name" Decode.string)
        (Decode.field "longitude" Decode.float)
        (Decode.field "house" Decode.int)

