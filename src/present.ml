(* present.ml

   Owner: Meira (primary), Saranya (secondary)

   Implementation of Present. *)

let tier_label = function
  | Tier.Sand -> "Sand"
  | Tier.Breeze -> "Breeze"
  | Tier.Updraft -> "Updraft"
  | Tier.JetStream -> "Jet Stream"
  | Tier.OneInACamillion -> "One in a Camillion"
  | Tier.Interstellar -> "Interstellar"

let outcome_emoji = function
  | Scoring.Correct Tier.Sand -> "\u{1F7EB}"
  | Scoring.Correct Tier.Breeze -> "\u{1F7E6}"
  | Scoring.Correct Tier.Updraft -> "\u{1F7E9}"
  | Scoring.Correct Tier.JetStream -> "\u{1F7EA}"
  | Scoring.Correct Tier.OneInACamillion -> "\u{1F7E7}"
  | Scoring.Correct Tier.Interstellar -> "\u{1F31F}"
  | Scoring.Incorrect -> "\u{2B1B}"
  | Scoring.Timed_out -> "\u{23F0}"

let share_text ~altitude outcomes =
  Printf.sprintf "Camillion: %d miles\n%s" altitude
    (String.concat "" (List.map outcome_emoji outcomes))

let altitude_fraction ~max_miles miles =
  if max_miles <= 0 then 0.
  else
    Float.min 1. (Float.max 0. (float_of_int miles /. float_of_int max_miles))

(* Scene background at fractions 0, 0.35, 0.7 and 1: desert sky, blue sky, deep
   blue, space. *)
let sky_stops =
  [
    (0., (247, 220, 170));
    (0.35, (110, 180, 235));
    (0.7, (25, 45, 110));
    (1., (5, 6, 25));
  ]

let lerp a b u =
  int_of_float (Float.round (float_of_int a +. (float_of_int (b - a) *. u)))

let rec blend t = function
  | (p0, (r0, g0, b0)) :: ((p1, (r1, g1, b1)) :: _ as rest) ->
      if t <= p1 then
        let u = (t -. p0) /. (p1 -. p0) in
        (lerp r0 r1 u, lerp g0 g1 u, lerp b0 b1 u)
      else blend t rest
  | [ (_, colour) ] -> colour
  | [] -> (0, 0, 0)

let sky_colour fraction =
  let t = Float.min 1. (Float.max 0. fraction) in
  let r, g, b = blend t sky_stops in
  Printf.sprintf "rgb(%d,%d,%d)" r g b

let max_balloons_shown = 12

(* (miles, scene level) pairs, in order. *)
let level_knots = [ (0, 0.); (16, 0.35); (64, 0.7); (100, 1.) ]

let rec level_from miles = function
  | (m0, l0) :: ((m1, l1) :: _ as rest) ->
      if miles <= m1 then
        l0 +. ((l1 -. l0) *. float_of_int (miles - m0) /. float_of_int (m1 - m0))
      else level_from miles rest
  | [ (_, l) ] -> l
  | [] -> 0.

let scene_level miles = level_from (max 0 miles) level_knots

let zone_name miles =
  if miles < 8 then "Desert"
  else if miles < 32 then "Open sky"
  else if miles < 100 then "Jet stream"
  else "Space"

let ground_visibility miles =
  Float.max 0. (1. -. (float_of_int (max 0 miles) /. 16.))

let balloon_row n =
  let shown = max 0 (min max_balloons_shown n) in
  String.concat "" (List.init shown (fun _ -> "\u{1F388}"))