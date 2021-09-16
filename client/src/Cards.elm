module Cards exposing (Card(..), Id, cardsDecoder, id, image, name)

import Dict
import Enum exposing (Enum)
import Json.Decode as Decode exposing (Decoder, int, list, map, string)
import Json.Decode.Pipeline exposing (optional, required)


type alias Id =
    String


type alias Name =
    String


type alias Text =
    String


type alias Illustrator =
    String


type alias Image =
    String


type Pack
    = Core
    | BloodAndAlchemy
    | Promo


pack : Enum Pack
pack =
    Enum.create
        [ ( "Blood & Alchemy", BloodAndAlchemy )
        , ( "Core", Core )
        , ( "Season 0 Promo", Promo )
        ]


type Clan
    = Brujah
    | Malkavian
    | ThinBlood
    | Toreador
    | Tremere
    | Ventrue


clan : Enum Clan
clan =
    Enum.create
        [ ( "brujah", Brujah )
        , ( "malkavian", Malkavian )
        , ( "thin-blood", ThinBlood )
        , ( "toreador", Toreador )
        , ( "tremere", Tremere )
        , ( "ventrue", Ventrue )
        ]


type alias BloodPotency =
    Int


type BloodPotencyRequirement
    = BloodPotencyRequirement Int
    | NoBloodPotencyRequirement


type alias Attribute =
    Int


type alias Damage =
    Int


type alias Shield =
    Int


type Discipline
    = Animalism
    | Auspex
    | Celerity
    | Dominate
    | Fortitude
    | Obfuscate
    | Potence
    | Presence
    | Protean
    | BloodSorcery
    | ThinBloodAlchemy


discipline : Enum Discipline
discipline =
    Enum.create
        [ ( "animalism", Animalism )
        , ( "auspex", Auspex )
        , ( "celerity", Celerity )
        , ( "dominate", Dominate )
        , ( "fortitude", Fortitude )
        , ( "obfuscate", Obfuscate )
        , ( "potence", Potence )
        , ( "presence", Presence )
        , ( "protean", Protean )
        , ( "blood sorcery", BloodSorcery )
        , ( "thin-blood alchemy", ThinBloodAlchemy )
        ]


type Trait
    = Action
    | Alchemy
    | Attack
    | Conspiracy
    | InfluenceModifier
    | Ongoing
    | Reaction
    | Ritual
    | Scheme
    | Special
    | Title
    | UnhostedAction


trait : Enum Trait
trait =
    Enum.create
        [ ( "action", Action )
        , ( "alchemy", Alchemy )
        , ( "attack", Attack )
        , ( "conspiracy", Conspiracy )
        , ( "influence modifier", InfluenceModifier )
        , ( "ongoing", Ongoing )
        , ( "reaction", Reaction )
        , ( "ritual", Ritual )
        , ( "scheme", Scheme )
        , ( "special", Special )
        , ( "title", Title )
        , ( "unhosted action", UnhostedAction )
        ]


type AttackType
    = Physical
    | Social
    | Mental
    | Ranged


attackType : Enum AttackType
attackType =
    Enum.create
        [ ( "physical", Physical )
        , ( "social", Social )
        , ( "mental", Mental )
        , ( "ranged", Ranged )
        ]


type alias Agenda =
    { id : Id, name : Name, text : Text, illustrator : Illustrator, image : Image, set : Pack }


type alias Haven =
    { id : Id, name : Name, text : Text, illustrator : Illustrator, image : Image, set : Pack }


type alias Faction =
    { id : Id
    , name : Name
    , text : Text
    , illustrator : Illustrator
    , image : Image
    , set : Pack
    , clan : Clan
    , bloodPotency : BloodPotency
    , physical : Attribute
    , social : Attribute
    , mental : Attribute
    , disciplines : List Discipline
    }


type alias Library =
    { id : Id
    , name : Name
    , text : Text
    , illustrator : Illustrator
    , image : Image
    , set : Pack
    , bloodPotency : BloodPotencyRequirement
    , damage : Maybe Damage
    , shield : Maybe Shield
    , traits : List Trait
    , attackType : List AttackType
    }


type Card
    = AgendaCard Agenda
    | HavenCard Haven
    | FactionCard Faction
    | LibraryCard Library



----------
-- HELPERS
----------


id : Card -> String
id card =
    case card of
        AgendaCard c ->
            c.id

        HavenCard c ->
            c.id

        FactionCard c ->
            c.id

        LibraryCard c ->
            c.id


name : Card -> String
name card =
    case card of
        AgendaCard c ->
            c.name

        HavenCard c ->
            c.name

        FactionCard c ->
            c.name

        LibraryCard c ->
            c.name


image : Card -> String
image card =
    case card of
        AgendaCard c ->
            c.image

        HavenCard c ->
            c.image

        FactionCard c ->
            c.image

        LibraryCard c ->
            c.image



----------
-- DECODER
----------


cardsDecoder : Decoder (Dict.Dict Id Card)
cardsDecoder =
    list cardDecoder |> map Dict.fromList


cardDecoder : Decoder ( Id, Card )
cardDecoder =
    Decode.succeed decoderForCardType
        |> required "types" (list string)
        |> Decode.andThen identity


decoderForCardType : List String -> Decoder ( Id, Card )
decoderForCardType cardTypes =
    case cardTypes of
        [ "agenda" ] ->
            agendaDecoder

        [ "haven" ] ->
            havenDecoder

        [ "character" ] ->
            factionDecoder

        _ ->
            libraryDecoder


agendaDecoder : Decoder ( Id, Card )
agendaDecoder =
    Decode.succeed Agenda
        |> decodeId
        |> decodeName
        |> decodeText
        |> decodeIllustrator
        |> decodeImage
        |> decodeSet
        |> map (\agenda -> ( agenda.id, AgendaCard agenda ))


havenDecoder : Decoder ( Id, Card )
havenDecoder =
    Decode.succeed Haven
        |> decodeId
        |> decodeName
        |> decodeText
        |> decodeIllustrator
        |> decodeImage
        |> decodeSet
        |> map (\haven -> ( haven.id, HavenCard haven ))


factionDecoder : Decoder ( Id, Card )
factionDecoder =
    Decode.succeed Faction
        |> decodeId
        |> decodeName
        |> decodeText
        |> decodeIllustrator
        |> decodeImage
        |> decodeSet
        |> decodeClan
        |> decodeBloodPotency
        |> decodePhysical
        |> decodeSocial
        |> decodeMental
        |> decodeDisciplines
        |> map (\faction -> ( faction.id, FactionCard faction ))


libraryDecoder : Decoder ( Id, Card )
libraryDecoder =
    Decode.succeed Library
        |> decodeId
        |> decodeName
        |> decodeText
        |> decodeIllustrator
        |> decodeImage
        |> decodeSet
        |> decodeBloodPotencyRequirement
        |> decodeDamage
        |> decodeShields
        |> decodeTraits
        |> decodeAttackType
        |> map (\library -> ( library.id, LibraryCard library ))



-- FIELD DECODERS


decodeBloodPotency : Decoder (Int -> b) -> Decoder b
decodeBloodPotency =
    required "bloodPotency" int


decodeBloodPotencyRequirement : Decoder (BloodPotencyRequirement -> b) -> Decoder b
decodeBloodPotencyRequirement =
    optional "bloodPotency" (map BloodPotencyRequirement int) NoBloodPotencyRequirement


decodeDamage : Decoder (Maybe Damage -> b) -> Decoder b
decodeDamage =
    optional "damage" (map Just int) Nothing


decodeId : Decoder (String -> b) -> Decoder b
decodeId =
    required "id" string


decodeIllustrator : Decoder (String -> b) -> Decoder b
decodeIllustrator =
    required "illustrator" string


decodeImage : Decoder (String -> b) -> Decoder b
decodeImage =
    required "image" string


decodeName : Decoder (String -> b) -> Decoder b
decodeName =
    required "name" string


decodeShields : Decoder (Maybe Shield -> b) -> Decoder b
decodeShields =
    optional "shield" (map Just int) Nothing


decodeText : Decoder (String -> b) -> Decoder b
decodeText =
    required "text" string


decodePhysical : Decoder (Int -> b) -> Decoder b
decodePhysical =
    required "attributePhysical" int


decodeSocial : Decoder (Int -> b) -> Decoder b
decodeSocial =
    required "attributeSocial" int


decodeMental : Decoder (Int -> b) -> Decoder b
decodeMental =
    required "attributeMental" int


decodeDisciplines : Decoder (List Discipline -> b) -> Decoder b
decodeDisciplines =
    required "disciplines" (list discipline.decoder)


decodeAttackType : Decoder (List AttackType -> b) -> Decoder b
decodeAttackType =
    optional "attackType" (list attackType.decoder) []


decodeTraits : Decoder (List Trait -> b) -> Decoder b
decodeTraits =
    required "types" (list trait.decoder)


decodeClan : Decoder (Clan -> b) -> Decoder b
decodeClan =
    required "clan" clan.decoder


decodeSet : Decoder (Pack -> b) -> Decoder b
decodeSet =
    required "set" pack.decoder
