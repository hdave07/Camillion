(* scoring.mli

   Owner: Saranya (primary), Teju (secondary)

   Turns a tier into balloons and altitude (miles); a timed-out answer adds
   nothing.

   See docs/ARCHITECTURE.md. No implementation yet. *)

type outcome =
  | Correct of Tier.t
  | Incorrect
  | Timed_out

val time_limit_seconds : float
val miles_for_tier : Tier.t -> int

val classify_submission :
  elapsed_seconds:float -> matched_tier:Tier.t option -> outcome
(** Classify a submission using the time since its prompt began. [matched_tier]
    is [Some tier] for a valid answer and [None] otherwise. A submission at
    exactly 25 seconds is a timeout. *)

val altitude_gain : outcome -> int
