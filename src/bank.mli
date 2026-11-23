(* bank.mli

   Owner: Roma (primary), Harini (secondary)

   Answer bank: types for prompts, accepted answers, aliases and tiers, plus the
   loader that validates bank JSON and reports malformed entries instead of
   loading them. Takes already-parsed JSON (no file IO here).

   See docs/ARCHITECTURE.md. No implementation yet. *)

type answer = {
  canonical : string;
  aliases : string list;
  tier : Tier.t;
}

type prompt = {
  id : string;
  text : string;
  answers : answer list;
}

type error = {
  location : string;
  message : string;
}

val load : Yojson.Basic.t -> prompt list * error list
val parse_answer : Yojson.Basic.t -> (answer, string) result
