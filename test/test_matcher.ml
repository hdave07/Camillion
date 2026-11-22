(* test_matcher.ml

   Owner: Teju

   OUnit tests for Normalizer and Matcher: accepted answers and near misses that
   must be rejected. *)

open OUnit2
open Camillion

(* --- Normalizer --- *)

let norm_test name input expected =
  name >:: fun _ ->
  assert_equal expected (Normalizer.normalize input) ~printer:(fun s ->
      "\"" ^ s ^ "\"")

let normalizer_tests =
  [
    norm_test "lowercase" "CHAD" "chad";
    norm_test "trim and collapse spaces" "   golden    retriever  "
      "golden retriever";
    norm_test "accent" "Café" "cafe";
    norm_test "accents and ampersand" "São Tomé & Príncipe"
      "sao tome and principe";
    norm_test "uppercase accent" "ÉCLAIR" "eclair";
    norm_test "apostrophe removed" "Côte d'Ivoire" "cote divoire";
    norm_test "curly apostrophe removed" "O\xE2\x80\x99Neill" "oneill";
    norm_test "periods removed" "U.S.A." "usa";
    norm_test "hyphen becomes space" "Guinea-Bissau" "guinea bissau";
    norm_test "leading article dropped" "The Gambia" "gambia";
    norm_test "article kept when it is the only word" "The" "the";
    norm_test "plural on last word only" "golden retrievers" "golden retriever";
    norm_test "plural ies" "Blueberries" "blueberry";
    norm_test "plural ches" "peaches" "peach";
    norm_test "plural xes" "boxes" "box";
    norm_test "ss not stripped" "glass" "glass";
    norm_test "is not stripped" "Paris" "paris";
    norm_test "us not stripped" "cactus" "cactus";
    norm_test "short word not stripped" "gas" "gas";
    norm_test "empty" "" "";
    norm_test "only punctuation" "?!..." "";
  ]

(* --- Edit distance and typo budget --- *)

let int_test name expected actual =
  name >:: fun _ -> assert_equal expected actual ~printer:string_of_int

let distance_tests =
  [
    int_test "identical" 0 (Matcher.edit_distance "chad" "chad");
    int_test "empty vs word" 3 (Matcher.edit_distance "" "abc");
    int_test "classic kitten/sitting" 3
      (Matcher.edit_distance "kitten" "sitting");
    int_test "adjacent swap counts as one" 1
      (Matcher.edit_distance "kenya" "keyna");
    int_test "one insertion" 1 (Matcher.edit_distance "ngeria" "nigeria");
    int_test "typos for 4 letters" 0 (Matcher.max_typos "chad");
    int_test "typos for 5 letters" 1 (Matcher.max_typos "kenya");
    int_test "typos for 8 letters" 1 (Matcher.max_typos "eswatini");
    int_test "typos for 9+ letters" 2 (Matcher.max_typos "burkina faso");
  ]

(* --- Matcher --- *)

let e name aliases tier = { Matcher.name; aliases; tier }

let africa =
  [
    e "Nigeria" [] Tier.Sand;
    e "Kenya" [] Tier.Breeze;
    e "Côte d'Ivoire" [ "Ivory Coast" ] Tier.Breeze;
    e "Chad" [] Tier.Updraft;
    e "Burkina Faso" [ "Burkina" ] Tier.JetStream;
    e "Eswatini" [ "Swaziland" ] Tier.OneInACamillion;
    e "São Tomé and Príncipe" [ "Sao Tome" ] Tier.Interstellar;
  ]

let middle_east = [ e "Iran" [] Tier.Sand; e "Iraq" [] Tier.Breeze ]

let fruit =
  [
    e "Banana" [] Tier.Sand;
    e "Blueberry" [] Tier.Breeze;
    e "Peach" [] Tier.Updraft;
  ]

(* Two answers one edit apart, to check that a tie is rejected. *)
let tie = [ e "Tonga" [] Tier.Sand; e "Tango" [] Tier.Sand ]

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
    accepts "exact" africa "Chad" "Chad";
    accepts "case and punctuation" africa "  CHAD!! " "Chad";
    accepts "alias" africa "swaziland" "Eswatini";
    accepts "accented name typed without accents" africa "sao tome and principe"
      "São Tomé and Príncipe";
    accepts "accented name with ampersand" africa "São Tomé & Príncipe"
      "São Tomé and Príncipe";
    accepts "short alias" africa "Sao Tome" "São Tomé and Príncipe";
    accepts "apostrophe in name" africa "cote divoire" "Côte d'Ivoire";
    accepts "multi-word alias" africa "ivory coast" "Côte d'Ivoire";
    accepts "missing letter (7 chars, 1 typo)" africa "Ngeria" "Nigeria";
    accepts "swapped letters (5 chars)" africa "Keyna" "Kenya";
    accepts "two typos on a long name" africa "Burkena Fasso" "Burkina Faso";
    accepts "plural input" fruit "bananas" "Banana";
    accepts "plural ies" fruit "blueberries" "Blueberry";
    accepts "plural es" fruit "Peaches" "Peach";
    accepts "short exact still wins" middle_east "Iraq" "Iraq";
    ( "returns the entry's tier" >:: fun _ ->
      match Matcher.match_answer africa "eswatini" with
      | Some x -> assert_equal Tier.OneInACamillion x.Matcher.tier
      | None -> assert_failure "expected a match" );
  ]

let rejected_tests =
  [
    rejects "typo on a 4-letter answer" africa "Chadd";
    rejects "iran/iraq style near miss" middle_east "Irak";
    rejects "different real country (Niger is not Nigeria)" africa "Niger";
    rejects "too many typos for 7 letters" africa "Nigeriaaa";
    rejects "answer to a different prompt" africa "France";
    rejects "answer from another prompt's list" africa "Iran";
    rejects "empty input" africa "";
    rejects "only spaces" africa "    ";
    rejects "only punctuation" africa "???";
    rejects "tie between two answers is ambiguous" tie "Tanga";
    rejects "empty answer list" [] "Chad";
  ]

let suite =
  "matcher"
  >::: [
         "normalizer" >::: normalizer_tests;
         "distance" >::: distance_tests;
         "accepted" >::: accepted_tests;
         "rejected" >::: rejected_tests;
       ]
