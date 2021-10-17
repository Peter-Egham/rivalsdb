module UI.FilterSelection exposing (Model, Msg(..), attackTypes, clans, disciplines, isAllowed, primaryTraits, secondaryTraits, stacks, update, view)

import Cards
import Html exposing (Html, div, input, label, span, text)
import Html.Attributes exposing (class, classList, title, type_)
import Html.Events exposing (onCheck)
import UI.Icon


type alias Model value msg =
    List ( value, ( Html msg, Bool ) )


stacks : Model Cards.CardStack msg
stacks =
    List.map modelHelper
        [ ( Cards.AgendaStack, ( "Agenda", UI.Icon.agendaCard ) )
        , ( Cards.HavenStack, ( "Haven", UI.Icon.haven ) )
        , ( Cards.FactionStack, ( "Faction", UI.Icon.faction ) )
        , ( Cards.LibraryStack, ( "Library", UI.Icon.library ) )
        ]


primaryTraits : Model Cards.Trait msg
primaryTraits =
    List.map modelHelper
        [ ( Cards.Action, ( "Action", UI.Icon.action ) )
        , ( Cards.UnhostedAction, ( "Unhosted Action", UI.Icon.unhostedAction ) )
        , ( Cards.Attack, ( "Attack", UI.Icon.attack ) )
        , ( Cards.Reaction, ( "Reaction", UI.Icon.reaction ) )
        , ( Cards.InfluenceModifier, ( "Influence Modifier", UI.Icon.influenceModifier ) )
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
    [ ( Cards.Physical, ( UI.Icon.physical, False ) )
    , ( Cards.Social, ( UI.Icon.social, False ) )
    , ( Cards.Mental, ( UI.Icon.mental, False ) )
    , ( Cards.Ranged, ( UI.Icon.ranged, False ) )
    ]


clans : Model Cards.Clan msg
clans =
    [ ( Cards.Brujah, ( UI.Icon.brujah, False ) )
    , ( Cards.Gangrel, ( UI.Icon.gangrel, False ) )
    , ( Cards.Malkavian, ( UI.Icon.malkavian, False ) )
    , ( Cards.Nosferatu, ( UI.Icon.nosferatu, False ) )
    , ( Cards.ThinBlood, ( UI.Icon.thinBlood, False ) )
    , ( Cards.Toreador, ( UI.Icon.toreador, False ) )
    , ( Cards.Tremere, ( UI.Icon.tremere, False ) )
    , ( Cards.Ventrue, ( UI.Icon.ventrue, False ) )
    ]


disciplines : Model Cards.Discipline msg
disciplines =
    [ ( Cards.Animalism, ( UI.Icon.animalism, False ) )
    , ( Cards.Auspex, ( UI.Icon.auspex, False ) )
    , ( Cards.Celerity, ( UI.Icon.celerity, False ) )
    , ( Cards.Dominate, ( UI.Icon.dominate, False ) )
    , ( Cards.Fortitude, ( UI.Icon.fortitude, False ) )
    , ( Cards.Obfuscate, ( UI.Icon.obfuscate, False ) )
    , ( Cards.Potence, ( UI.Icon.potence, False ) )
    , ( Cards.Presence, ( UI.Icon.presence, False ) )
    , ( Cards.Protean, ( UI.Icon.protean, False ) )
    , ( Cards.BloodSorcery, ( UI.Icon.bloodSorcery, False ) )
    , ( Cards.ThinBloodAlchemy, ( UI.Icon.thinBloodAlchemy, False ) )
    ]


modelHelper : ( a, ( String, Html msg ) ) -> ( a, ( Html msg, Bool ) )
modelHelper ( a, ( b, c ) ) =
    ( a, ( span [ title b, class "fltrslct-icon_wrapper" ] [ c ], False ) )


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
