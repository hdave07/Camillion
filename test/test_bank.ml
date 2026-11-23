(* test_bank.ml

   Owner: Roma

   OUnit tests for Bank (including malformed entries).

   See docs/ARCHITECTURE.md. *)

open OUnit2
open Camillion

(** A helper for creating a valid answer in JSON format. *)
let valid_answer =
  `Assoc
    [
      ("canonical", `String "Python");
      ("aliases", `List [ `String "Python 3"; `String "Py" ]);
      ("tier", `String "Sand");
    ]

(** A helper for creating a valid prompt in JSON format. *)
let valid_prompt =
  `Assoc
    [
      ("id", `String "prompt_1");
      ("text", `String "Name a programming language");
      ("answers", `List [ valid_answer ]);
    ]

let test_parse_valid_answer _ =
  match Bank.parse_answer valid_answer with
  | Ok answer ->
      assert_equal "Python" answer.canonical;
      assert_equal [ "Python 3"; "Py" ] answer.aliases;
      assert_equal Tier.Sand answer.tier
  | Error message -> assert_failure message

let test_parse_invalid_answer _ =
  let invalid_answer =
    `Assoc
      [
        ("canonical", `String "Python");
        ("aliases", `List []);
        ("tier", `String "Unknown");
      ]
  in
  match Bank.parse_answer invalid_answer with
  | Ok _ -> assert_failure "Expected an invalid answer"
  | Error _ -> ()

let test_load_valid_bank _ =
  let json = `List [ valid_prompt ] in
  let prompts, errors = Bank.load json in
  assert_equal 1 (List.length prompts);
  assert_equal 0 (List.length errors)

let test_load_invalid_root _ =
  let prompts, errors = Bank.load (`String "not a list") in
  assert_equal 0 (List.length prompts);
  assert_equal 1 (List.length errors)

let test_load_keeps_valid_answers _ =
  let invalid_answer =
    `Assoc
      [
        ("canonical", `String "Java");
        ("aliases", `List []);
        ("tier", `String "Unknown");
      ]
  in
  let prompt =
    `Assoc
      [
        ("id", `String "prompt_2");
        ("text", `String "Name a programming language");
        ("answers", `List [ valid_answer; invalid_answer; valid_answer ]);
      ]
  in
  let prompts, errors = Bank.load (`List [ prompt ]) in
  assert_equal 1 (List.length prompts);
  assert_equal 2 (List.length (List.hd prompts).answers);
  assert_equal 1 (List.length errors)

let test_load_skips_prompt_with_no_valid_answers _ =
  let invalid_answer =
    `Assoc
      [
        ("canonical", `String "Java");
        ("aliases", `List []);
        ("tier", `String "Unknown");
      ]
  in
  let prompt =
    `Assoc
      [
        ("id", `String "prompt_3");
        ("text", `String "Name a programming language");
        ("answers", `List [ invalid_answer ]);
      ]
  in
  let prompts, errors = Bank.load (`List [ prompt ]) in
  assert_equal 0 (List.length prompts);
  assert_equal 2 (List.length errors)

let test_load_skips_prompt_missing_id _ =
  let prompt =
    `Assoc
      [
        ("text", `String "Name a programming language");
        ("answers", `List [ valid_answer ]);
      ]
  in
  let prompts, errors = Bank.load (`List [ prompt ]) in
  assert_equal 0 (List.length prompts);
  assert_equal 1 (List.length errors)

let test_load_skips_prompt_with_empty_answers _ =
  let prompt =
    `Assoc
      [
        ("id", `String "prompt_4");
        ("text", `String "Name a programming language");
        ("answers", `List []);
      ]
  in
  let prompts, errors = Bank.load (`List [ prompt ]) in
  assert_equal 0 (List.length prompts);
  assert_equal 1 (List.length errors)

let suite =
  "bank"
  >::: [
         "parse valid answer" >:: test_parse_valid_answer;
         "parse invalid answer" >:: test_parse_invalid_answer;
         "load valid bank" >:: test_load_valid_bank;
         "load invalid root" >:: test_load_invalid_root;
       ]
