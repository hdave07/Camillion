(* engine.mli

   Owner: Saranya (primary), Teju (secondary)

   Round engine: picks a round's distinct prompts from the bank using an
   explicit seed (date-based for the daily challenge). Pure and reproducible.
   Also game state and the countdown rule.

   See docs/ARCHITECTURE.md. *)

type 'prompt t

val pick_prompts :
  seed:int ->
  count:int ->
  prompt_id:('prompt -> string) ->
  'prompt list ->
  ('prompt list, string) result
(** [pick_prompts ~seed ~count ~prompt_id prompts] selects [count] distinct
    prompts. The same seed and ordered input produce the same round. Returns an
    error if [count] is less than 1 or exceeds the number of distinct prompt
    IDs. If an ID occurs twice, its first entry is used. *)

val start : 'prompt list -> 'prompt t
(** [start prompts] creates a round at zero miles. *)

val current_prompt : 'prompt t -> 'prompt option
(** The next prompt to answer, or [None] once the round is complete. *)

val altitude : 'prompt t -> int
(** Total altitude gained so far, in miles. *)

val submit :
  elapsed_seconds:float ->
  matched_tier:Tier.t option ->
  'prompt t ->
  (Scoring.outcome * 'prompt t) option
(** [submit ~elapsed_seconds ~matched_tier round] scores the current prompt and
    advances the round. Time is measured from the start of that prompt. Returns
    [None] if the round is already complete. *)
