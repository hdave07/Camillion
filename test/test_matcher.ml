(* test_matcher.ml

   Owner: Teju

   OUnit tests for Normalizer and Matcher: accepted answers and near misses that
   must be rejected. Every expected value below was worked out by hand from the
   rules in normalizer.mli and matcher.mli, not by running the code. The answer
   lists match the demo round in server/demo_round.ml. *)

open OUnit2
open Camillion

(* ---------- Normalizer ---------- *)

let norm_test name input expected =
  name >:: fun _ ->
  assert_equal expected (Normalizer.normalize input) ~printer:(fun s ->
      "\"" ^ s ^ "\"")

let normalizer_tests =
  [
    norm_test "lowercase" "FROZEN" "frozen";
    norm_test "trim and collapse spaces" "   treasure    planet  "
      "treasure planet";
    norm_test "accent" "Café" "cafe";
    norm_test "several accents" "Crème Brûlée" "creme brulee";
    norm_test "uppercase accent" "ÉCLAIR" "eclair";
    norm_test "ampersand" "Lilo & Stitch" "lilo and stitch";
    norm_test "apostrophe removed" "Emperor's New Groove" "emperors new groove";
    norm_test "curly apostrophe removed" "Emperor\xE2\x80\x99s New Groove"
      "emperors new groove";
    norm_test "periods removed" "Mr. Incredible" "mr incredible";
    norm_test "other symbols dropped" "WALL\xC2\xB7E" "walle";
    norm_test "hyphen becomes space" "Spider-Man" "spider man";
    norm_test "leading article dropped" "The Lion King" "lion king";
    norm_test "article kept when it is the only word" "The" "the";
    norm_test "plural on last word only" "toy stories" "toy story";
    norm_test "plural ies" "Blueberries" "blueberry";
    norm_test "plural ches" "peaches" "peach";
    norm_test "plural xes" "boxes" "box";
    norm_test "plural rule also hits names (same on both sides)" "Gates" "gate";
    norm_test "ss not stripped" "glass" "glass";
    norm_test "us not stripped" "campus" "campus";
    norm_test "is not stripped" "Paris" "paris";
    norm_test "short word not stripped" "gas" "gas";
    norm_test "empty" "" "";
    norm_test "only punctuation" "?!..." "";
  ]

(* ---------- Edit distance and typo budget ---------- *)

let int_test name expected actual =
  name >:: fun _ -> assert_equal expected actual ~printer:string_of_int

let distance_tests =
  [
    int_test "identical" 0 (Matcher.edit_distance "moana" "moana");
    int_test "empty vs word" 3 (Matcher.edit_distance "" "abc");
    int_test "classic kitten/sitting" 3
      (Matcher.edit_distance "kitten" "sitting");
    int_test "adjacent swap counts as one" 1
      (Matcher.edit_distance "duffeild" "duffield");
    int_test "one insertion" 1 (Matcher.edit_distance "aladin" "aladdin");
    int_test "typos for 4 letters" 0 (Matcher.max_typos "olin");
    int_test "typos for 5 letters" 1 (Matcher.max_typos "mulan");
    int_test "typos for 8 letters" 1 (Matcher.max_typos "zootopia");
    int_test "typos for 9+ letters" 2 (Matcher.max_typos "treasure planet");
  ]

(* ---------- Matcher ---------- *)

let e name aliases tier = { Matcher.name; aliases; tier }

let fruit =
  [
    e "Apple" [] Tier.Sand;
    e "Banana" [] Tier.Sand;
    e "Strawberry" [] Tier.Breeze;
    e "Blueberry" [] Tier.Breeze;
    e "Peach" [] Tier.Updraft;
    e "Lychee" [ "Litchi" ] Tier.JetStream;
  ]

let cornell =
  [
    e "Olin Library" [ "Olin" ] Tier.Sand;
    e "Willard Straight Hall" [ "Willard Straight"; "WSH" ] Tier.Sand;
    e "Uris Library" [ "Uris" ] Tier.Breeze;
    e "Duffield Hall" [ "Duffield" ] Tier.Breeze;
    e "Gates Hall" [ "Gates" ] Tier.Updraft;
    e "Statler Hall" [ "Statler" ] Tier.Updraft;
    e "Bailey Hall" [ "Bailey" ] Tier.JetStream;
    e "Barton Hall" [ "Barton" ] Tier.OneInACamillion;
    e "McGraw Tower" [ "McGraw"; "Clocktower"; "Clock Tower" ] Tier.Interstellar;
  ]

let disney =
  [
    e "Frozen" [] Tier.Sand;
    e "The Lion King" [] Tier.Sand;
    e "Moana" [] Tier.Breeze;
    e "Aladdin" [] Tier.Breeze;
    e "Mulan" [] Tier.Updraft;
    e "Zootopia" [ "Zootropolis" ] Tier.JetStream;
    e "The Emperor's New Groove" [] Tier.OneInACamillion;
    e "Treasure Planet" [] Tier.Interstellar;
  ]

(* Two answers one edit away from the same typo, to check that a tie is rejected
   and that an exact match still beats a close neighbor. *)
let lemon_melon = [ e "Lemon" [] Tier.Sand; e "Melon" [] Tier.Breeze ]

let show = function
  | None -> "None"
  | Some x -> "Some " ^ x.Matcher.name

let accepts name entries input expected =
  name >:: fun _ ->
  match Matcher.match_answer entries input with
  | Some x -> assert_equal expected x.Matcher.name ~printer:(fun s -> s)
  | None -> assert_failure ("expected " ^ expected ^ ", got no match")

let rejects name entries input =
  name >:: fun _ ->
  assert_equal None (Matcher.match_answer entries input) ~printer:show

let accepted_tests =
  [
    accepts "exact" disney "Frozen" "Frozen";
    accepts "case and punctuation" disney "  FROZEN!! " "Frozen";
    accepts "alias" disney "zootropolis" "Zootopia";
    accepts "without leading article" disney "Lion King" "The Lion King";
    accepts "with leading article" disney "the lion king" "The Lion King";
    accepts "apostrophe and article dropped" disney "emperors new groove"
      "The Emperor's New Groove";
    accepts "missing letter (7 chars, 1 typo)" disney "Aladin" "Aladdin";
    accepts "swapped letters (8 chars)" cornell "Duffeild" "Duffield Hall";
    accepts "short alias" cornell "Olin" "Olin Library";
    accepts "multi-word alias" cornell "willard straight"
      "Willard Straight Hall";
    accepts "alias with leading article" cornell "the clock tower"
      "McGraw Tower";
    accepts "two typos on a long name" disney "Tresure Plannet"
      "Treasure Planet";
    accepts "one typo on a long name" fruit "Strawbery" "Strawberry";
    accepts "fruit alias" fruit "litchi" "Lychee";
    accepts "plural input" fruit "bananas" "Banana";
    accepts "plural ies" fruit "blueberries" "Blueberry";
    accepts "plural es" fruit "Peaches" "Peach";
    accepts "name the plural rule changes" cornell "Gates" "Gates Hall";
    accepts "exact beats a close neighbor" lemon_melon "Melon" "Melon";
    ( "returns the entry's tier" >:: fun _ ->
      match Matcher.match_answer disney "treasure planet" with
      | Some x -> assert_equal Tier.Interstellar x.Matcher.tier
      | None -> assert_failure "expected a match" );
  ]

let rejected_tests =
  [
    rejects "typo on a 4-letter alias" cornell "Urus";
    rejects "real Cornell building not on the list" cornell "Rhodes Hall";
    rejects "real Disney movie not on the list" disney "Cars";
    rejects "close but different fruit (Pear is not Peach)" fruit "Pear";
    rejects "too many typos for 7 letters" disney "Alladdinn";
    rejects "answer to a different prompt" disney "Banana";
    rejects "answer from another prompt's list" cornell "Frozen";
    rejects "empty input" disney "";
    rejects "only spaces" disney "    ";
    rejects "only punctuation" disney "???";
    rejects "tie between two answers is ambiguous" lemon_melon "Lelon";
    rejects "empty answer list" [] "Frozen";
  ]

let suite =
  "matcher"
  >::: [
         "normalizer" >::: normalizer_tests;
         "distance" >::: distance_tests;
         "accepted" >::: accepted_tests;
         "rejected" >::: rejected_tests;
       ]
