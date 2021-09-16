module UI.FilterSelection exposing (Model, Msg(..), attackTypes, isAllowed, primaryTraits, secondaryTraits, update, view)

import Cards
import Html exposing (Html, div, input, label, span, text)
import Html.Attributes exposing (class, classList, title, type_)
import Html.Events exposing (onCheck)


type alias Model value msg =
    List ( value, ( Html msg, Bool ) )


primaryTraits : Model Cards.Trait msg
primaryTraits =
    [ ( Cards.Action, ( span [ title "Action" ] [ text "🚶" ], False ) )
    , ( Cards.UnhostedAction, ( span [ title "Unhosted Action" ] [ text "🧘" ], False ) )
    , ( Cards.Attack, ( span [ title "Attack" ] [ text "🗡️" ], False ) )
    , ( Cards.Reaction, ( span [ title "Reaction" ] [ text "🛡️" ], False ) )
    , ( Cards.InfluenceModifier, ( span [ title "Influence Modifier" ] [ text "🤝" ], False ) )
    ]


secondaryTraits : Model Cards.Trait msg
secondaryTraits =
    [ ( Cards.Ongoing, ( span [ title "Ongoing" ] [ text "♻️" ], False ) )
    , ( Cards.Scheme, ( span [ title "Scheme" ] [ text "🗳️" ], False ) )
    , ( Cards.Title, ( span [ title "Title" ] [ text "🤴" ], False ) )
    , ( Cards.Conspiracy, ( span [ title "Conspiracy" ] [ text "🙊" ], False ) )
    , ( Cards.Alchemy, ( span [ title "Alchemy" ] [ text "⚗️" ], False ) )
    , ( Cards.Ritual, ( span [ title "Ritual" ] [ text "🧙" ], False ) )
    , ( Cards.Special, ( span [ title "Special" ] [ text "❄️" ], False ) )
    ]


attackTypes : Model Cards.AttackType msg
attackTypes =
    [ ( Cards.Physical, ( span [ title "Physical" ] [ text "🤜" ], False ) )
    , ( Cards.Social, ( span [ title "Social" ] [ text "👄" ], False ) )
    , ( Cards.Mental, ( span [ title "Mental" ] [ text "🧠" ], False ) )
    , ( Cards.Ranged, ( span [ title "Ranged" ] [ text "🎯" ], False ) )
    ]


type Msg value
    = ChangedValue value Bool


update : Msg value -> Model value msg -> Model value msg
update msg model =
    case msg of
        ChangedValue changedKey newValue ->
            List.map
                (\option ->
                    if Tuple.first option == changedKey then
                        Tuple.mapSecond (Tuple.mapSecond (always newValue)) option

                    else
                        option
                )
                model


view : (Msg value -> msg) -> Model value msg -> Html msg
view msg options =
    div [ class "fltrslct" ] <|
        List.map
            (\( value, ( icon, isActive ) ) ->
                label
                    [ classList
                        [ ( "fltrslct-option", True )
                        , ( "fltrslct-option--actv", isActive )
                        ]
                    ]
                    [ div [ class "fltrslct-icon" ] [ icon ]
                    , input
                        [ type_ "checkbox"
                        , onCheck (ChangedValue value >> msg)
                        ]
                        []
                    ]
            )
            options


isAllowed : (Cards.Card -> List value) -> Model value msg -> Cards.Card -> Bool
isAllowed toValues model card =
    let
        whitelist =
            List.filterMap
                (\( key, ( _, isOn ) ) ->
                    if isOn then
                        Just key

                    else
                        Nothing
                )
                model
    in
    if List.isEmpty whitelist then
        True

    else
        toValues card |> List.any (\cardValue -> List.member cardValue whitelist)
