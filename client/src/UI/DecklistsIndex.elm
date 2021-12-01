module UI.DecklistsIndex exposing (view)

import Cards
import Deck exposing (DeckPostSave)
import Gen.Route as Route
import Html exposing (Html, a, div, li, p, span, text, ul)
import Html.Attributes exposing (class, href)
import UI.Card
import UI.Icon


view : List DeckPostSave -> Html unknown
view model =
    ul [ class "deckindex" ]
        (model |> List.map viewDecklistEntry)


viewDecklistEntry : DeckPostSave -> Html msg
viewDecklistEntry deck =
    li [ class "deckindexitem" ]
        [ a [ class "deckindexcard", href <| Route.toHref (Route.Deck__View__Id_ { id = deck.meta.id }) ]
            [ div [ class "deckindexcard__illustration" ] [ illustrationImage deck.decklist ]
            , div [ class "deckindexcard__illustration-overlay" ] []
            , div [ class "deckindexcard__content" ]
                [ p [ class "deckindexcard__name" ] [ text <| Deck.displayName deck.meta.name ]
                , p [ class "deckindexcard__byline" ] [ text "by: ", text <| Deck.ownerDisplayName deck.meta ]
                , p [ class "deckindexcard__clans" ]
                    (Deck.clansInFaction deck.decklist.faction
                        |> List.map
                            (\( clan, _ ) ->
                                span [ class "deckindexcard__clan" ] [ UI.Icon.clan UI.Icon.Negative clan ]
                            )
                    )
                , p [ class "deckindexcard__summary" ]
                    [ Deck.leader deck.decklist |> Maybe.map (.name >> text) |> Maybe.withDefault (text "Unknown Leader")
                    , text " • "
                    , deck.decklist.haven |> Maybe.map (.name >> text) |> Maybe.withDefault (text "Unknown Haven")
                    , text " • "
                    , deck.decklist.agenda |> Maybe.map (.name >> text) |> Maybe.withDefault (text "Unknown Agenda")
                    ]
                ]
            ]
        ]


illustrationImage : Deck.Decklist -> Html msg
illustrationImage decklist =
    case Deck.leader decklist of
        Just leader ->
            UI.Card.lazy (Cards.FactionCard leader)

        Nothing ->
            case Deck.fallbackLeader decklist of
                Just fallbackLeader ->
                    UI.Card.lazy (Cards.FactionCard fallbackLeader)

                Nothing ->
                    span [] []
