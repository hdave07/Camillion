(* present.mli

   Owner: Meira (primary), Saranya (secondary)

   Display logic for the browser front end, kept pure so it can be tested
   natively and still compile to JavaScript: tier names, the emoji share row,
   how high the camel sits in the scene, and the sky colour at that height. *)

val tier_label : Tier.t -> string
(** The tier's display name, e.g. [JetStream] is ["Jet Stream"]. *)

val outcome_emoji : Scoring.outcome -> string
(** One emoji per prompt for the share row: a coloured square for each tier
    (from brown for [Sand] up to a star for [Interstellar]), a black square for
    [Incorrect], and an alarm clock for [Timed_out]. *)

val share_text : altitude:int -> Scoring.outcome list -> string
(** [share_text ~altitude outcomes] is a two-line, Wordle-style summary: the
    title and final altitude in miles, then one emoji per prompt in order. *)

val altitude_fraction : max_miles:int -> int -> float
(** [altitude_fraction ~max_miles miles] is how far up the scene the camel is,
    from [0.] (on the sand) to [1.] (top of the scene). It is [miles] divided by
    [max_miles], clamped to that range; [0.] if [max_miles] is not positive. *)

val sky_colour : float -> string
(** [sky_colour fraction] is a CSS [rgb(r,g,b)] colour for the scene background
    at that altitude fraction (clamped to [0.] to [1.]): a warm desert sky at
    the bottom, blue in the middle, and near-black space at the top, blending
    linearly between those four stops. *)

val scene_level : int -> float
(** [scene_level miles] is where the background sits on the [sky_colour] scale
    for a total of [miles]: [0.] at 0 miles, [0.35] (blue sky) at 16, [0.7]
    (deep blue) at 64 and [1.] (space) at 100 or more, rising in a straight line
    between those points. It depends on absolute miles, not on round length, so
    one very rare answer reaches space by itself. A negative total counts as 0.
*)

val zone_name : int -> string
(** The name of the region the camel is in: ["Desert"] below 8 miles,
    ["Open sky"] below 32, ["Jet stream"] below 100 and ["Space"] from 100. *)

val ground_visibility : int -> float
(** [ground_visibility miles] is how much of the dunes still show, from [1.] at
    0 miles falling in a straight line to [0.] at 16 miles and above. *)

val balloon_row : int -> string
(** [balloon_row n] is [n] balloon emoji in a row, showing at most 12 so a large
    total still fits above the camel. Empty for [n <= 0]. *)
