(* main.ml

   Owner: everyone

   OUnit test runner. Each owner adds a test_<module>.ml file defining a suite and registers it here.

   See docs/ARCHITECTURE.md. No implementation yet. *)

let () =
  OUnit2.run_test_tt_main (OUnit2.( >::: ) "Camillion" [ Test_engine.suite ])
