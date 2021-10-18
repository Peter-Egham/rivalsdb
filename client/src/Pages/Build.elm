module Pages.Build exposing (Model, Msg, page)

import API.Decklist
import Browser.Navigation as Navigation exposing (Key)
import Cards exposing (Card)
import Deck exposing (Decklist)
import Dict
import Effect exposing (Effect)
import Gen.Params.Build exposing (Params)
import Gen.Route as Route
import Html exposing (..)
import Html.Attributes exposing (checked, class, classList, name, placeholder, type_)
import Html.Events exposing (onClick, onInput, onSubmit)
import Html.Keyed as Keyed
import Page
import Request
import Shared exposing (Collection)
import UI.Attribute
import UI.Card
import UI.FilterSelection
import UI.Icon as Icon
import UI.Layout.Template
import View exposing (View)


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page shared req =
    Page.advanced
        { init = init req
        , update = update shared
        , view = view shared
        , subscriptions = always Sub.none
        }



-- INIT


type alias Model =
    { stackFilters : UI.FilterSelection.Model Cards.CardStack Msg
    , primaryFilters : UI.FilterSelection.Model Cards.Trait Msg
    , secondaryFilters : UI.FilterSelection.Model Cards.Trait Msg
    , attackTypeFilters : UI.FilterSelection.Model Cards.AttackType Msg
    , clansFilters : UI.FilterSelection.Model Cards.Clan Msg
    , disciplineFilters : UI.FilterSelection.Model Cards.Discipline Msg
    , textFilter : Maybe String
    , showAllFilters : Bool
    , showCollectionImages : Bool
    , deck : Decklist
    , deckName : DeckName
    , key : Key
    }


type DeckName
    = Unnamed
    | Named String
    | BeingNamed String


deckNameToString : DeckName -> String
deckNameToString deckname =
    case deckname of
        Unnamed ->
            ""

        Named name ->
            name

        BeingNamed tempName ->
            tempName


init : Request.With Params -> ( Model, Effect Msg )
init req =
    ( { stackFilters = UI.FilterSelection.stacks
      , primaryFilters = UI.FilterSelection.primaryTraits
      , secondaryFilters = UI.FilterSelection.secondaryTraits
      , attackTypeFilters = UI.FilterSelection.attackTypes
      , clansFilters = UI.FilterSelection.clans
      , disciplineFilters = UI.FilterSelection.disciplines
      , textFilter = Nothing
      , showAllFilters = False
      , showCollectionImages = False
      , deck = Deck.empty
      , deckName = Unnamed
      , key = req.key
      }
    , Effect.none
    )


type Msg
    = FromShared Shared.Msg
    | FromStacksFilter (UI.FilterSelection.Msg Cards.CardStack)
    | FromPrimaryFilter (UI.FilterSelection.Msg Cards.Trait)
    | FromSecondaryFilter (UI.FilterSelection.Msg Cards.Trait)
    | FromAttackTypesFilter (UI.FilterSelection.Msg Cards.AttackType)
    | FromClansFilter (UI.FilterSelection.Msg Cards.Clan)
    | FromDisciplinesFilter (UI.FilterSelection.Msg Cards.Discipline)
    | TextFilterChanged String
    | ToggleShowAllFilters
    | ClearFilters
    | ToggleShowCollectionImages
    | ChangedDecklist ( Cards.Card, Int )
    | ChoseLeader Cards.Faction
    | Save
    | SavedDecklist API.Decklist.ResultCreate
    | StartRenameDeck
    | DeckNameChanged String
    | SaveNewDeckName


update : Shared.Model -> Msg -> Model -> ( Model, Effect Msg )
update shared msg model =
    case msg of
        TextFilterChanged text ->
            let
                cleanText =
                    text |> String.trim |> String.toLower
            in
            ( { model
                | textFilter =
                    if cleanText == "" then
                        Nothing

                    else
                        Just cleanText
              }
            , Effect.none
            )

        FromShared subMsg ->
            ( model, Effect.fromShared subMsg )

        FromStacksFilter subMsg ->
            ( { model | stackFilters = UI.FilterSelection.update subMsg model.stackFilters }, Effect.none )

        FromPrimaryFilter subMsg ->
            ( { model | primaryFilters = UI.FilterSelection.update subMsg model.primaryFilters }, Effect.none )

        FromSecondaryFilter subMsg ->
            ( { model | secondaryFilters = UI.FilterSelection.update subMsg model.secondaryFilters }, Effect.none )

        FromAttackTypesFilter subMsg ->
            ( { model | attackTypeFilters = UI.FilterSelection.update subMsg model.attackTypeFilters }, Effect.none )

        FromClansFilter subMsg ->
            ( { model | clansFilters = UI.FilterSelection.update subMsg model.clansFilters }, Effect.none )

        FromDisciplinesFilter subMsg ->
            ( { model | disciplineFilters = UI.FilterSelection.update subMsg model.disciplineFilters }, Effect.none )

        ClearFilters ->
            ( { model
                | stackFilters = UI.FilterSelection.stacks
                , primaryFilters = UI.FilterSelection.primaryTraits
                , secondaryFilters = UI.FilterSelection.secondaryTraits
                , attackTypeFilters = UI.FilterSelection.attackTypes
                , clansFilters = UI.FilterSelection.clans
                , disciplineFilters = UI.FilterSelection.disciplines
                , textFilter = Nothing
              }
            , Effect.none
            )

        ToggleShowAllFilters ->
            ( { model | showAllFilters = not model.showAllFilters }, Effect.none )

        ToggleShowCollectionImages ->
            ( { model | showCollectionImages = not model.showCollectionImages }, Effect.none )

        ChangedDecklist change ->
            ( { model | deck = Deck.setCard model.deck change }, Effect.none )

        ChoseLeader leader ->
            ( { model | deck = Deck.setLeader model.deck leader }, Effect.none )

        Save ->
            let
                deckName =
                    deckNameToString model.deckName
            in
            case ( shared.user, Deck.encode deckName model.deck ) of
                ( Just user, Just encodedDeck ) ->
                    ( model, API.Decklist.create SavedDecklist user.token encodedDeck |> Effect.fromCmd )

                ( _, _ ) ->
                    ( model, Effect.none )

        SavedDecklist (Ok deckId) ->
            ( model, Route.toHref (Route.View__Id_ { id = deckId }) |> Navigation.pushUrl model.key |> Effect.fromCmd )

        SavedDecklist (Err _) ->
            ( model, Effect.none )

        StartRenameDeck ->
            ( { model | deckName = BeingNamed "" }, Effect.none )

        DeckNameChanged newName ->
            case model.deckName of
                BeingNamed _ ->
                    ( { model | deckName = BeingNamed newName }, Effect.none )

                _ ->
                    ( model, Effect.none )

        SaveNewDeckName ->
            case model.deckName of
                BeingNamed newName ->
                    case String.trim newName of
                        "" ->
                            ( { model | deckName = Unnamed }, Effect.none )

                        trimmedName ->
                            ( { model | deckName = Named trimmedName }, Effect.none )

                _ ->
                    ( model, Effect.none )


viewDeckName : DeckName -> Html Msg
viewDeckName deckName =
    case deckName of
        Unnamed ->
            p []
                [ span [ class "decklist-titlename" ] [ text "Unnamed Deck" ]
                , span [ class "decklist-titleaction", onClick StartRenameDeck ]
                    [ text "(rename deck)" ]
                ]

        Named name ->
            p []
                [ span [ class "decklist-titlename" ] [ text name ]
                , span [ class "decklist-titleaction", onClick StartRenameDeck ]
                    [ text "(rename deck)" ]
                ]

        BeingNamed _ ->
            div []
                [ form [ onSubmit SaveNewDeckName ]
                    [ input [ placeholder "My Cool Deck", onInput DeckNameChanged ] []
                    , button [ type_ "submit" ] [ text "ok" ]
                    ]
                ]


view : Shared.Model -> Model -> View Msg
view shared model =
    UI.Layout.Template.view FromShared
        shared
        [ div [ class "deckbldr" ]
            [ viewActions shared.user
            , div [ class "deckbldr-decklist" ]
                [ div [ class "decklist" ]
                    [ div [ class "decklist-title" ] [ viewDeckName model.deckName ]
                    , div [ class "decklist-core", class "decklist-core--agenda" ]
                        [ p [ class "decklist-section_header" ]
                            [ text "Agenda: "
                            , text <| Maybe.withDefault "Unknown" <| Maybe.map .name model.deck.agenda
                            ]
                        , div [ class "decklist-core_image" ]
                            [ model.deck.agenda
                                |> Maybe.map (Cards.AgendaCard >> UI.Card.lazy)
                                |> Maybe.withDefault (text "Unknown Agenda")
                            ]
                        ]
                    , div [ class "decklist-core", class "decklist-core--haven" ]
                        [ p [ class "decklist-section_header" ]
                            [ text "Haven: "
                            , text <| Maybe.withDefault "Unknown" <| Maybe.map .name model.deck.haven
                            ]
                        , div [ class "decklist-core_image" ]
                            [ model.deck.haven
                                |> Maybe.map (Cards.HavenCard >> UI.Card.lazy)
                                |> Maybe.withDefault (text "Unknown Haven")
                            ]
                        ]
                    , div [ class "decklist-core", class "decklist-core--leader" ]
                        [ p [ class "decklist-section_header" ]
                            [ text "Leader: "
                            , text <| Maybe.withDefault "Unknown" <| Maybe.map .name (Deck.leader model.deck)
                            ]
                        , div [ class "decklist-core_image" ]
                            [ Deck.leader model.deck
                                |> Maybe.map (Cards.FactionCard >> UI.Card.lazy)
                                |> Maybe.withDefault (text "Unknown Leader")
                            ]
                        ]
                    , div [ class "decklist-faction" ]
                        [ div
                            [ class "decklist-section_header"
                            , classList [ ( "decklist-section_header--invalid", not <| Deck.isValidFaction model.deck ) ]
                            ]
                            [ h3 [ class "decklist-section_header_name" ] [ text "Faction" ]
                            , div [ class "decklist-section_header_extra" ] <| viewClansInFaction model.deck.faction
                            ]
                        , viewFactionList model.deck
                        ]
                    , div [ class "decklist-library" ]
                        [ h3
                            [ class "decklist-section_header"
                            , classList [ ( "decklist-section_header--invalid", not <| Deck.isValidLibrary model.deck ) ]
                            ]
                            (text "Library"
                                :: (case cardCount <| Dict.values model.deck.library of
                                        0 ->
                                            []

                                        n ->
                                            [ text " (", text <| String.fromInt n, text ")" ]
                                   )
                            )
                        , viewLibraryList model.deck
                        ]
                    ]
                ]
            , div [ class "deckbldr-choices" ]
                [ div [ class "fltrhead" ]
                    [ h2 [ class "fltrhead-name" ] [ text "Filters " ]
                    , span [ onClick ToggleShowAllFilters, class "fltrhead-primary", class "fltrhead-action" ]
                        [ text <|
                            if model.showAllFilters then
                                "(hide filters)"

                            else
                                "(show more)"
                        ]
                    , span [ onClick ClearFilters, class "fltrhead-secondary", class "fltrhead-action" ] [ text "Clear filters" ]
                    ]
                , div [ class "deckbldr-filters" ] <|
                    List.intersperse (text " ")
                        (viewMainFilters model
                            ++ (if model.showAllFilters then
                                    viewSecondaryFilters model

                                else
                                    []
                               )
                        )
                , div [ class "fltrhead" ]
                    [ h2 [ class "fltrhead-name" ] [ text "Cards " ]
                    , span [ onClick ToggleShowCollectionImages, class "fltrhead-primary", class "fltrhead-action" ]
                        [ text <|
                            if model.showCollectionImages then
                                "(hide images)"

                            else
                                "(show images)"
                        ]
                    ]
                , div [ class "deckbldr-collection" ] <|
                    if model.showCollectionImages then
                        viewCardListImages shared.collection model

                    else
                        viewCardList shared.collection model
                ]
            ]
        ]


viewActions : Maybe Shared.User -> Html Msg
viewActions user =
    div [ class "deckbldr-actions" ]
        [ ul [ class "actions-list" ]
            [ li
                (user
                    |> Maybe.map
                        (always
                            [ class "actions-item"
                            , onClick Save
                            ]
                        )
                    |> Maybe.withDefault
                        [ class "actions-item"
                        , class "actions-item--inactive"
                        ]
                )
                [ span [ class "actions-icon" ] [ Icon.icon ( Icon.Save, Icon.Standard ) ]
                , span [ class "actions-description" ] [ text "Save" ]
                ]
            ]
        ]


viewClansInFaction : Deck.Faction -> List (Html Msg)
viewClansInFaction faction =
    Dict.values faction
        |> List.foldl
            (\( card, _ ) usedClans ->
                if List.member card.clan usedClans then
                    usedClans

                else
                    card.clan :: usedClans
            )
            []
        |> List.map
            (\clan ->
                span [ class "decklist-clan_entry" ]
                    [ span [ class "decklist-clan_clan" ] [ Icon.clan clan ] ]
            )


viewFactionList : Decklist -> Html Msg
viewFactionList deck =
    let
        characters =
            Dict.values deck.faction |> List.map Tuple.first

        sortedCharacters =
            List.sortBy (.bloodPotency >> negate) characters
    in
    ul [ class "deckfact" ]
        (sortedCharacters
            |> List.map
                (\c ->
                    li
                        [ class "deckfact-entry"
                        , classList [ ( "deckfact-entry--leader", Deck.isLeader deck c ) ]
                        ]
                        ([ span
                            [ class "deckfact-leader_option"
                            , classList [ ( "deckfact-leader_option--leader", Deck.isLeader deck c ) ]
                            , onClick (ChoseLeader c)
                            ]
                            (if Deck.isLeader deck c then
                                [ Icon.icon ( Icon.Leader, Icon.Standard ) ]

                             else
                                []
                            )
                         , span [ class "deckfact-bp" ] [ UI.Attribute.bloodPotency c.bloodPotency ]
                         , span [ class "deckfact-clan" ] [ Icon.clan c.clan ]
                         , span [ class "deckfact-name" ] [ text c.name ]
                         ]
                            ++ (c.disciplines
                                    |> List.map (span [ class "deckfact-discipline" ] << List.singleton << Icon.discipline)
                               )
                        )
                )
        )


cardCount : List ( a, Int ) -> Int
cardCount =
    List.foldl (\( _, n ) sum -> sum + n) 0


viewLibraryList : Decklist -> Html Msg
viewLibraryList deck =
    let
        { actions, combat, other } =
            groupLibraryCards deck

        viewGroup name group =
            if cardCount group < 1 then
                []

            else
                [ h4 [ class "decklist-library_section_header" ]
                    [ text name
                    , text " ("
                    , text <| String.fromInt <| cardCount group
                    , text ")"
                    ]
                , ul []
                    (group
                        |> List.map
                            (\( c, n ) ->
                                li [ class "decklist-library_entry" ]
                                    [ span [] [ text (String.fromInt n) ]
                                    , span [] [ text "× " ]
                                    , span [] [ text c.name ]
                                    ]
                            )
                    )
                ]
    in
    div [ class "decklist-library" ] <|
        List.concat
            [ viewGroup "Actions" actions
            , viewGroup "Combat" combat
            , viewGroup "Other" other
            ]


groupLibraryCards : Decklist -> { actions : List ( Cards.Library, Int ), combat : List ( Cards.Library, Int ), other : List ( Cards.Library, Int ) }
groupLibraryCards deck =
    let
        groups =
            { actions = [], combat = [], other = [] }

        assignToGroup ( card, n ) oldGroups =
            if List.any (\trait -> trait == Cards.Action || trait == Cards.UnhostedAction) card.traits then
                { oldGroups | actions = ( card, n ) :: oldGroups.actions }

            else if List.any (\trait -> trait == Cards.Attack || trait == Cards.Reaction) card.traits then
                { oldGroups | combat = ( card, n ) :: oldGroups.combat }

            else
                { oldGroups | other = ( card, n ) :: oldGroups.other }
    in
    Dict.values deck.library |> List.foldl assignToGroup groups


viewMainFilters : Model -> List (Html Msg)
viewMainFilters model =
    [ div [ class "deckbldr-flaggroup" ] [ UI.FilterSelection.view FromStacksFilter model.stackFilters ]
    , div [ class "deckbldr-flaggroup" ] [ UI.FilterSelection.view FromPrimaryFilter model.primaryFilters ]
    , div [ class "deckbldr-flaggroup" ] [ UI.FilterSelection.view FromClansFilter model.clansFilters ]
    ]


viewSecondaryFilters : Model -> List (Html Msg)
viewSecondaryFilters model =
    [ div [ class "deckbldr-flaggroup" ] [ UI.FilterSelection.view FromSecondaryFilter model.secondaryFilters ]
    , div [ class "deckbldr-flaggroup" ] [ UI.FilterSelection.view FromAttackTypesFilter model.attackTypeFilters ]
    , div [ class "deckbldr-flaggroup" ] [ UI.FilterSelection.view FromDisciplinesFilter model.disciplineFilters ]
    ]


viewCardList : Collection -> Model -> List (Html Msg)
viewCardList collection model =
    [ Keyed.ul [ class "deckbldr-collectionitems--rows" ] <|
        List.map (\c -> ( Cards.id c, viewCardListRow model.deck c )) <|
            cardsToShow collection model
    ]


viewCardListRow : Decklist -> Card -> Html Msg
viewCardListRow deck card =
    li [ class "deckbldr-collectionitem--row" ]
        [ span [ class "deckbldr-rowpiece_quant--row" ] [ viewQuantityPicker card (Deck.copiesInDeck deck card) ]
        , span [ class "deckbldr-rowpiece_name" ] [ text <| Cards.name card ]
        , span [ class "deckbldr-rowpiece_props" ]
            (case card of
                Cards.FactionCard props ->
                    [ span [ class "deckbldr-rowpiece_clan" ] [ Icon.clan props.clan ]
                    , span [ class "deckbldr-rowpiece_bp" ] [ UI.Attribute.bloodPotency props.bloodPotency ]
                    , span [ class "deckbldr-rowpiece_physical" ] [ UI.Attribute.physical props.physical ]
                    , span [ class "deckbldr-rowpiece_social" ] [ UI.Attribute.social props.social ]
                    , span [ class "deckbldr-rowpiece_mental" ] [ UI.Attribute.mental props.mental ]
                    , span [ class "deckbldr-rowpiece_disciplines" ]
                        (props.disciplines
                            |> List.map (span [ class "deckbldr-rowpiece_discipline" ] << List.singleton << Icon.discipline)
                        )
                    ]

                Cards.LibraryCard props ->
                    [ span [ class "deckbldr-rowpiece_clan" ]
                        [ props.clan |> Maybe.map Icon.clan |> Maybe.withDefault (text "")
                        ]
                    , span [ class "deckbldr-rowpiece_bp" ] [ UI.Attribute.bloodPotencyRequirement props.bloodPotency ]
                    , span [ class "deckbldr-rowpiece_damage" ] [ UI.Attribute.damage props.damage ]
                    , span [ class "deckbldr-rowpiece_shields" ] [ UI.Attribute.shield props.shield ]
                    , span [ class "deckbldr-rowpiece_types" ]
                        (props.attackType
                            |> List.map (span [ class "deckbldr-rowpiece_type" ] << List.singleton << Icon.attackType)
                        )
                    ]

                _ ->
                    []
            )
        ]


viewQuantityPicker : Card -> Int -> Html Msg
viewQuantityPicker card copiesInDeck =
    div [ class "quantpick", class ("quantpick--" ++ (String.fromInt <| Cards.maxPerDeck card)) ] <|
        (Cards.maxPerDeck card
            |> List.range 0
            |> List.map
                (\n ->
                    label
                        [ class "quantpick-option"
                        , classList [ ( "quantpick-option--active", n == copiesInDeck ) ]
                        ]
                        [ text <| String.fromInt n
                        , input
                            [ type_ "radio"
                            , name <| "count-" ++ Cards.id card
                            , checked <| n == copiesInDeck
                            , onClick <| ChangedDecklist ( card, n )
                            ]
                            []
                        ]
                )
        )


viewCardListImages : Collection -> Model -> List (Html Msg)
viewCardListImages collection model =
    [ Keyed.ul [ class "deckbldr-collectionitems--images" ] <|
        List.map (\c -> ( Cards.id c, viewCardListImage model.deck c )) <|
            cardsToShow collection model
    ]


viewCardListImage : Decklist -> Card -> Html Msg
viewCardListImage deck card =
    li [ class "deckbldr-collectionitem--image" ]
        [ UI.Card.lazy card
        , div [ class "deckbldr-rowpiece_quant--image" ] [ viewQuantityPicker card (Deck.copiesInDeck deck card) ]
        ]


cardsToShow : Collection -> Model -> List Card
cardsToShow collection model =
    filteredCards collection model |> List.sortWith cardSort


filteredCards : Collection -> Model -> List Card
filteredCards collection model =
    let
        cards =
            Dict.values collection
    in
    case model.textFilter of
        Nothing ->
            List.filter (filterFlags model) cards

        Just needle ->
            List.filter (Cards.findTextInCard needle) cards
                |> List.filter (filterFlags model)


filterFlags : Model -> Card -> Bool
filterFlags model card =
    UI.FilterSelection.isAllowed Cards.clanRequirement model.clansFilters card
        && UI.FilterSelection.isAllowed Cards.traits model.secondaryFilters card
        && UI.FilterSelection.isAllowed Cards.stack model.stackFilters card
        && UI.FilterSelection.isAllowed Cards.discipline model.disciplineFilters card
        && UI.FilterSelection.isAllowed Cards.traits model.primaryFilters card
        && UI.FilterSelection.isAllowed Cards.attackTypes model.attackTypeFilters card


cardSort : Card -> Card -> Order
cardSort a b =
    let
        stack card =
            case card of
                Cards.AgendaCard _ ->
                    1

                Cards.HavenCard _ ->
                    2

                Cards.FactionCard _ ->
                    3

                Cards.LibraryCard _ ->
                    4
    in
    case compare (stack a) (stack b) of
        EQ ->
            case compare (Cards.bloodPotency a) (Cards.bloodPotency b) of
                EQ ->
                    compare (Cards.name a) (Cards.name b)

                ord ->
                    ord

        ord ->
            ord
