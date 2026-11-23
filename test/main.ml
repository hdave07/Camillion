(* main.ml

   Owner: everyone

   OUnit test runner. Each owner adds a test_<module>.ml file defining a suite and registers it here.

   See docs/ARCHITECTURE.md. *)

open OUnit2

let () = run_test_tt_main ("all" >::: [ Test_parse.suite ])
