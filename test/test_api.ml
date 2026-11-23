(* test_api.ml

   Owner: Teju

   OUnit tests for Api: the JSON the server sends is exactly the JSON the
   browser (Meira) parses, and malformed requests are rejected with a message
   instead of crashing the server. *)

open OUnit2
open Camillion

let all_tiers =
  Tier.[ Sand; Breeze; Updraft; JetStream; OneInACamillion; Interstellar ]

let tier_tests =
  [
    ( "tier strings round-trip" >:: fun _ ->
      List.iter
        (fun t ->
          assert_equal (Some t) (Api.tier_of_string (Api.tier_to_string t)))
        all_tiers );
    ( "tier string spelling" >:: fun _ ->
      assert_equal "jet_stream" (Api.tier_to_string Tier.JetStream);
      assert_equal "one_in_a_camillion"
        (Api.tier_to_string Tier.OneInACamillion) );
    ("unknown tier" >:: fun _ -> assert_equal None (Api.tier_of_string "gold"));
  ]

let round =
  {
    Api.prompts =
      [
        { Api.id = "disney"; text = "Name a Disney animated movie" };
        { Api.id = "fruit"; text = "Name a fruit" };
      ];
  }

let json_string j = Yojson.Safe.to_string j

let round_tests =
  [
    ( "round JSON shape" >:: fun _ ->
      assert_equal
        ~printer:(fun s -> s)
        {|{"prompts":[{"id":"disney","text":"Name a Disney animated movie"},{"id":"fruit","text":"Name a fruit"}]}|}
        (json_string (Api.round_response_to_json round)) );
    ( "round round-trips" >:: fun _ ->
      assert_equal (Ok round)
        (Api.round_response_of_json (Api.round_response_to_json round)) );
    ( "empty round" >:: fun _ ->
      assert_equal
        ~printer:(fun s -> s)
        {|{"prompts":[]}|}
        (json_string (Api.round_response_to_json { Api.prompts = [] })) );
  ]

let parse s = Yojson.Safe.from_string s

let is_error = function
  | Ok _ -> false
  | Error _ -> true

let request_tests =
  [
    ( "valid request" >:: fun _ ->
      assert_equal
        (Ok { Api.prompt_id = "disney"; text = "mulan" })
        (Api.answer_request_of_json
           (parse {|{"prompt_id":"disney","text":"mulan"}|})) );
    ( "extra fields ignored" >:: fun _ ->
      assert_equal
        (Ok { Api.prompt_id = "disney"; text = "mulan" })
        (Api.answer_request_of_json
           (parse {|{"text":"mulan","prompt_id":"disney","x":1}|})) );
    ( "missing text" >:: fun _ ->
      assert_bool "should be Error"
        (is_error (Api.answer_request_of_json (parse {|{"prompt_id":"a"}|}))) );
    ( "text is not a string" >:: fun _ ->
      assert_bool "should be Error"
        (is_error
           (Api.answer_request_of_json (parse {|{"prompt_id":"a","text":5}|})))
    );
    ( "not an object" >:: fun _ ->
      assert_bool "should be Error"
        (is_error (Api.answer_request_of_json (parse {|["chad"]|}))) );
  ]

let matched =
  Api.Matched
    { answer = "Mulan"; tier = Tier.Updraft; balloons = 3; miles = 16 }

let response_tests =
  [
    ( "matched JSON shape" >:: fun _ ->
      assert_equal
        ~printer:(fun s -> s)
        {|{"result":"match","answer":"Mulan","tier":"updraft","balloons":3,"miles":16}|}
        (json_string (Api.answer_response_to_json matched)) );
    ( "no match JSON shape" >:: fun _ ->
      assert_equal
        ~printer:(fun s -> s)
        {|{"result":"no_match"}|}
        (json_string (Api.answer_response_to_json Api.No_match)) );
    ( "matched round-trips" >:: fun _ ->
      assert_equal (Ok matched)
        (Api.answer_response_of_json (Api.answer_response_to_json matched)) );
    ( "no match round-trips" >:: fun _ ->
      assert_equal (Ok Api.No_match)
        (Api.answer_response_of_json (Api.answer_response_to_json Api.No_match))
    );
    ( "unknown tier rejected" >:: fun _ ->
      assert_bool "should be Error"
        (is_error
           (Api.answer_response_of_json
              (parse
                 {|{"result":"match","answer":"x","tier":"gold","balloons":1,"miles":1}|})))
    );
  ]

let suite =
  "api"
  >::: [
         "tier" >::: tier_tests;
         "round" >::: round_tests;
         "request" >::: request_tests;
         "response" >::: response_tests;
       ]
