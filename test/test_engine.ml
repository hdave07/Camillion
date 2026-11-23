(* test_engine.ml

   Owner: Saranya

   OUnit tests for Engine: same seed gives the same round; prompts are distinct.

   See docs/ARCHITECTURE.md. *)

open OUnit2
open Camillion

let pick prompts =
  Engine.pick_prompts ~seed:42 ~count:3 ~prompt_id:Fun.id prompts

let test_selection _ =
  let bank = [ "a"; "b"; "a"; "c"; "d" ] in
  match pick bank with
  | Error message -> assert_failure message
  | Ok prompts ->
      assert_equal 3 (List.length prompts);
      assert_equal 3 (List.length (List.sort_uniq String.compare prompts));
      assert_equal (Ok prompts) (pick bank)

let test_too_few_prompts _ =
  match pick [ "a"; "a"; "b" ] with
  | Error _ -> ()
  | Ok _ -> assert_failure "Expected an error for fewer than three IDs"

let test_round _ =
  let submit elapsed_seconds round =
    match
      Engine.submit ~elapsed_seconds ~matched_tier:(Some Tier.Updraft) round
    with
    | Some result -> result
    | None -> assert_failure "Expected a prompt to score"
  in
  let round = Engine.start [ "a"; "b" ] in
  assert_equal (Some "a") (Engine.current_prompt round);
  let outcome, round = submit 24.9 round in
  assert_equal (Scoring.Correct Tier.Updraft) outcome;
  assert_equal 16 (Engine.altitude round);
  assert_equal (Some "b") (Engine.current_prompt round);
  let outcome, round = submit 25.0 round in
  assert_equal Scoring.Timed_out outcome;
  assert_equal 16 (Engine.altitude round);
  assert_equal None (Engine.current_prompt round);
  assert_equal None
    (Engine.submit ~elapsed_seconds:1.0 ~matched_tier:None round)

let suite =
  "engine"
  >::: [
         "repeatable selection with distinct IDs" >:: test_selection;
         "too few distinct prompts" >:: test_too_few_prompts;
         "round progression, altitude, and timeout" >:: test_round;
       ]
