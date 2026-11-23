(* demo_round.ml

   Owner: Teju (primary), Meira (secondary)

   TEMPORARY stand-in for Bank + Engine so the two endpoints work end to end
   before loader and round engine are merged. Tiers here are placeholders, not
   real rarity data. *)

open Camillion

type prompt = {
  id : string;
  text : string;
  answers : Matcher.entry list;
}

let e name aliases tier = { Matcher.name; aliases; tier }

let prompts =
  [
    {
      id = "fruit";
      text = "Name a fruit";
      answers =
        [
          e "Apple" [] Tier.Sand;
          e "Banana" [] Tier.Sand;
          e "Strawberry" [] Tier.Breeze;
          e "Mango" [] Tier.Breeze;
          e "Pomegranate" [] Tier.Updraft;
          e "Lychee" [ "Litchi" ] Tier.JetStream;
          e "Rambutan" [] Tier.OneInACamillion;
          e "Durian" [] Tier.Interstellar;
        ];
    };
    {
      id = "cornell";
      text = "Name a building on Cornell's campus";
      answers =
        [
          e "Olin Library" [ "Olin" ] Tier.Sand;
          e "Willard Straight Hall" [ "Willard Straight"; "WSH" ] Tier.Sand;
          e "Uris Library" [ "Uris" ] Tier.Breeze;
          e "Duffield Hall" [ "Duffield" ] Tier.Breeze;
          e "Gates Hall" [ "Gates" ] Tier.Updraft;
          e "Statler Hall" [ "Statler" ] Tier.Updraft;
          e "Bailey Hall" [ "Bailey" ] Tier.JetStream;
          e "Barton Hall" [ "Barton" ] Tier.OneInACamillion;
          e "McGraw Tower"
            [ "McGraw"; "Clocktower"; "Clock Tower" ]
            Tier.Interstellar;
        ];
    };
    {
      id = "disney";
      text = "Name a Disney animated movie";
      answers =
        [
          e "Frozen" [] Tier.Sand;
          e "The Lion King" [] Tier.Sand;
          e "Moana" [] Tier.Breeze;
          e "Aladdin" [] Tier.Breeze;
          e "Mulan" [] Tier.Updraft;
          e "Zootopia" [ "Zootropolis" ] Tier.JetStream;
          e "The Emperor's New Groove" [] Tier.OneInACamillion;
          e "Treasure Planet" [] Tier.Interstellar;
        ];
    };
  ]

let find id = List.find_opt (fun p -> p.id = id) prompts

(* TEMPORARY stand-in for Saranya's Scoring module. Miles follow the shared
   contract in docs/ARCHITECTURE.md section 5.1; balloon counts are a guess. *)
let score = function
  | Tier.Sand -> (1, 4)
  | Tier.Breeze -> (2, 8)
  | Tier.Updraft -> (3, 16)
  | Tier.JetStream -> (4, 32)
  | Tier.OneInACamillion -> (5, 64)
  | Tier.Interstellar -> (6, 100)
