(* scoring.ml

   Owner: Saranya (primary), Teju (secondary)

   Implementation of Scoring.

   See docs/ARCHITECTURE.md. No implementation yet. *)

type outcome = Correct of Tier.t | Incorrect | Timed_out

let time_limit_seconds = 25.0

let miles_for_tier (tier : Tier.t) : int =
  match tier with
  | Tier.Sand -> 4
  | Tier.Breeze -> 8
  | Tier.Updraft -> 16
  | Tier.JetStream -> 32
  | Tier.OneInACamillion -> 64
  | Tier.Interstellar -> 100

let classify_submission ~elapsed_seconds ~matched_tier =
  if elapsed_seconds >= time_limit_seconds then Timed_out
  else match matched_tier with Some tier -> Correct tier | None -> Incorrect

let altitude_gain = function
  | Correct tier -> miles_for_tier tier
  | Incorrect | Timed_out -> 0
