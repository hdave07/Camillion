(* demo_round.ml

   Owner: Teju (primary), Meira (secondary)

   TEMPORARY stand-in for Bank + Engine so the two endpoints work end to end
   before Roma's loader and Saranya's round engine are merged. Once they are: -
   load data/bank/*.json at startup and pass it to Bank, - ask Engine for the
   round's prompts, - delete this file. Tiers here are placeholders, not real
   rarity data. *)

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
      id = "africa";
      text = "Name a country in Africa";
      answers =
        [
          e "Nigeria" [] Tier.Sand;
          e "Egypt" [] Tier.Sand;
          e "Kenya" [] Tier.Breeze;
          e "Morocco" [] Tier.Breeze;
          e "Côte d'Ivoire" [ "Ivory Coast" ] Tier.Updraft;
          e "Chad" [] Tier.Updraft;
          e "Burkina Faso" [ "Burkina" ] Tier.JetStream;
          e "Eswatini" [ "Swaziland" ] Tier.OneInACamillion;
          e "São Tomé and Príncipe" [ "Sao Tome" ] Tier.Interstellar;
        ];
    };
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
      id = "planet";
      text = "Name a planet in our solar system";
      answers =
        [
          e "Earth" [] Tier.Sand;
          e "Mars" [] Tier.Sand;
          e "Jupiter" [] Tier.Breeze;
          e "Saturn" [] Tier.Breeze;
          e "Venus" [] Tier.Updraft;
          e "Neptune" [] Tier.JetStream;
          e "Uranus" [] Tier.OneInACamillion;
          e "Mercury" [] Tier.Interstellar;
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
