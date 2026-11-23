(* test_present.ml

   Owner: Meira (primary), Saranya (secondary)

   Tests for Present. Expected values are worked out by hand from the
   definitions in present.mli, not copied from the program's output. *)

open OUnit2
open Camillion

let tiers =
  [
    Tier.Sand;
    Tier.Breeze;
    Tier.Updraft;
    Tier.JetStream;
    Tier.OneInACamillion;
    Tier.Interstellar;
  ]

let label_tests =
  [
    ( "tier labels" >:: fun _ ->
      assert_equal
        [
          "Sand";
          "Breeze";
          "Updraft";
          "Jet Stream";
          "One in a Camillion";
          "Interstellar";
        ]
        (List.map Present.tier_label tiers)
        ~printer:(String.concat "; ") );
  ]

let share_tests =
  [
    ( "each outcome has its own emoji" >:: fun _ ->
      let outcomes =
        Scoring.Incorrect :: Scoring.Timed_out
        :: List.map (fun t -> Scoring.Correct t) tiers
      in
      let emoji = List.map Present.outcome_emoji outcomes in
      assert_equal (List.length emoji)
        (List.length (List.sort_uniq compare emoji))
        ~msg:"emoji must be distinct" );
    ( "share text: tiers, a miss and a timeout" >:: fun _ ->
      (* 4 miles (Sand) + 64 miles (One in a Camillion) = 68. *)
      assert_equal "Camillion: 68 miles\n\u{1F7EB}\u{1F7E7}\u{2B1B}\u{23F0}"
        (Present.share_text ~altitude:68
           [
             Scoring.Correct Tier.Sand;
             Scoring.Correct Tier.OneInACamillion;
             Scoring.Incorrect;
             Scoring.Timed_out;
           ])
        ~printer:Fun.id );
    ( "share text: no prompts" >:: fun _ ->
      assert_equal "Camillion: 0 miles\n"
        (Present.share_text ~altitude:0 [])
        ~printer:Fun.id );
  ]

let fraction_tests =
  let check name ~max_miles miles expected =
    name >:: fun _ ->
    assert_equal expected
      (Present.altitude_fraction ~max_miles miles)
      ~printer:string_of_float
  in
  [
    check "on the sand" ~max_miles:700 0 0.;
    check "halfway" ~max_miles:700 350 0.5;
    check "a quarter" ~max_miles:400 100 0.25;
    check "exactly at the top" ~max_miles:700 700 1.;
    check "past the top is clamped" ~max_miles:700 900 1.;
    check "negative is clamped" ~max_miles:700 (-5) 0.;
    check "no maximum" ~max_miles:0 10 0.;
  ]

let sky_tests =
  let check name fraction expected =
    name >:: fun _ ->
    assert_equal expected (Present.sky_colour fraction) ~printer:Fun.id
  in
  [
    check "ground" 0. "rgb(247,220,170)";
    check "first stop" 0.35 "rgb(110,180,235)";
    check "second stop" 0.7 "rgb(25,45,110)";
    check "space" 1. "rgb(5,6,25)";
    check "below zero is clamped" (-1.) "rgb(247,220,170)";
    check "above one is clamped" 2. "rgb(5,6,25)";
    (* Halfway between the first two stops: r = (247+110)/2 = 178.5 -> 179, g =
       (220+180)/2 = 200, b = (170+235)/2 = 202.5 -> 203. *)
    check "halfway between ground and first stop" 0.175 "rgb(179,200,203)";
    ( "sky darkens with altitude" >:: fun _ ->
      let brightness f =
        Scanf.sscanf (Present.sky_colour f) "rgb(%d,%d,%d)" (fun r g b ->
            r + g + b)
      in
      let samples = [ 0.; 0.1; 0.2; 0.35; 0.5; 0.7; 0.85; 1. ] in
      let values = List.map brightness samples in
      assert_equal values
        (List.sort (fun a b -> compare b a) values)
        ~printer:(fun l -> String.concat "," (List.map string_of_int l)) );
  ]

let scene_tests =
  let level name miles expected =
    name >:: fun _ ->
    assert_equal expected (Present.scene_level miles) ~printer:string_of_float
  in
  let zone name miles expected =
    name >:: fun _ ->
    assert_equal expected (Present.zone_name miles) ~printer:Fun.id
  in
  let ground name miles expected =
    name >:: fun _ ->
    assert_equal expected
      (Present.ground_visibility miles)
      ~printer:string_of_float
  in
  [
    level "no miles" 0 0.;
    level "negative counts as zero" (-4) 0.;
    level "blue sky at 16" 16 0.35;
    level "halfway to blue sky" 8 0.175;
    level "deep blue at 64" 64 0.7;
    level "space at 100" 100 1.;
    level "past space stays at one" 400 1.;
    (* From 64 to 100 the level rises 0.3: 82 is halfway, so 0.7 + 0.15. *)
    level "halfway from deep blue to space" 82 0.85;
    ( "one interstellar answer reaches space" >:: fun _ ->
      assert_equal 1.
        (Present.scene_level (Scoring.miles_for_tier Tier.Interstellar)) );
    zone "start" 0 "Desert";
    zone "one sand answer" 4 "Desert";
    zone "breeze" 8 "Open sky";
    zone "updraft" 16 "Open sky";
    zone "just under jet stream" 31 "Open sky";
    zone "jet stream" 32 "Jet stream";
    zone "one in a camillion" 64 "Jet stream";
    zone "space" 100 "Space";
    ground "all of it at 0" 0 1.;
    ground "half at 8" 8 0.5;
    ground "gone at 16" 16 0.;
    ground "stays gone" 90 0.;
  ]

let balloon_tests =
  [
    ("none" >:: fun _ -> assert_equal "" (Present.balloon_row 0));
    ("negative is empty" >:: fun _ -> assert_equal "" (Present.balloon_row (-3)));
    ( "three" >:: fun _ ->
      assert_equal "\u{1F388}\u{1F388}\u{1F388}" (Present.balloon_row 3) );
    ( "capped at twelve" >:: fun _ ->
      assert_equal (Present.balloon_row 12) (Present.balloon_row 40);
      (* Each balloon emoji is 4 bytes in UTF-8. *)
      assert_equal 48 (String.length (Present.balloon_row 40)) );
  ]

let suite =
  "present"
  >::: [
         "labels" >::: label_tests;
         "share" >::: share_tests;
         "altitude fraction" >::: fraction_tests;
         "sky colour" >::: sky_tests;
         "scene" >::: scene_tests;
         "balloons" >::: balloon_tests;
       ]
