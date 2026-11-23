(* main.ml

   Owner: everyone

   OUnit test runner. Each owner adds a test_<module>.ml file defining a suite
   and registers it in the list below. *)

open OUnit2

let () =
  run_test_tt_main
    ("camillion"
    >::: [
           Test_matcher.suite;
           Test_api.suite;
           Test_engine.suite;
           Test_bank.suite;
           Test_parse.suite;
           Test_present.suite;
         ])