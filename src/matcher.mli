(* matcher.mli

   Owner: Teju (primary), Meira (secondary)

   Matches normalized input against a prompt's answers and aliases, tolerating
   small typos without accepting wrong answers. Returns the matched answer's
   tier.

   Dev note: the matcher defines its own small [entry] type instead of depending
   on answer bank's types, so it can be built and tested before the bank loader
   exists.*)

type entry = {
  name : string;  (** Display name, e.g. "United States". *)
  aliases : string list;  (** Other accepted spellings, e.g. ["usa"; "us"]. *)
  tier : Tier.t;  (** Rarity tier awarded for this answer. *)
}
(** One accepted answer for a prompt. *)

val match_answer : entry list -> string -> entry option
(** [match_answer entries input] is [Some e] if [input] names the answer [e],
    and [None] otherwise. Matching works on {!Normalizer.normalize}d text:

    1. Exact: if the normalized input equals the normalized name or an alias of
    some entry, that entry wins. 2. Fuzzy: otherwise, each name/alias [k]
    accepts inputs within [max_typos k] edits ({!edit_distance}). The entry with
    the smallest distance wins. If two different entries tie for the smallest
    distance, the input is ambiguous and the result is [None]. Empty input (or
    input with no letters or digits) is [None]. *)

val max_typos : string -> int
(** [max_typos key] is how many edits a normalized name or alias of this length
    tolerates: 0 for 0-4, 1 for 5-8 characters, 2 for 9+. *)

val edit_distance : string -> string -> int
(** [edit_distance a b] is the fewest single-character insertions, deletions,
    substitutions, or swaps of two adjacent characters that turn [a] into [b].
*)
