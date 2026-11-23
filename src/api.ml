(* api.ml

   Owner: Teju (primary), Meira (secondary)

   Implementation of Api. *)

type prompt_view = {
  id : string;
  text : string;
}

type round_response = { prompts : prompt_view list }

type answer_request = {
  prompt_id : string;
  text : string;
}

type answer_response =
  | Matched of {
      answer : string;
      tier : Tier.t;
      balloons : int;
      miles : int;
    }
  | No_match

let tier_names =
  [
    (Tier.Sand, "sand");
    (Tier.Breeze, "breeze");
    (Tier.Updraft, "updraft");
    (Tier.JetStream, "jet_stream");
    (Tier.OneInACamillion, "one_in_a_camillion");
    (Tier.Interstellar, "interstellar");
  ]

let tier_to_string t = List.assoc t tier_names

let tier_of_string s =
  List.find_map (fun (t, name) -> if name = s then Some t else None) tier_names

(* --- small helpers for reading JSON objects --- *)

let ( let* ) = Result.bind

let field name = function
  | `Assoc kvs -> (
      match List.assoc_opt name kvs with
      | Some v -> Ok v
      | None -> Error ("missing field \"" ^ name ^ "\""))
  | _ -> Error "expected a JSON object"

let string_field name json =
  let* v = field name json in
  match v with
  | `String s -> Ok s
  | _ -> Error ("field \"" ^ name ^ "\" must be a string")

let int_field name json =
  let* v = field name json in
  match v with
  | `Int i -> Ok i
  | _ -> Error ("field \"" ^ name ^ "\" must be an integer")

let rec all_ok = function
  | [] -> Ok []
  | Ok x :: rest ->
      let* xs = all_ok rest in
      Ok (x :: xs)
  | Error e :: _ -> Error e

(* --- GET /api/round --- *)

let round_response_to_json r =
  `Assoc
    [
      ( "prompts",
        `List
          (List.map
             (fun (p : prompt_view) ->
               `Assoc [ ("id", `String p.id); ("text", `String p.text) ])
             r.prompts) );
    ]

let round_response_of_json json =
  let* ps = field "prompts" json in
  match ps with
  | `List items ->
      let* prompts =
        all_ok
          (List.map
             (fun item ->
               let* id = string_field "id" item in
               let* text = string_field "text" item in
               Ok { id; text })
             items)
      in
      Ok { prompts }
  | _ -> Error "field \"prompts\" must be a list"

(* --- POST /api/answer --- *)

let answer_request_to_json (r : answer_request) =
  `Assoc [ ("prompt_id", `String r.prompt_id); ("text", `String r.text) ]

let answer_request_of_json json =
  let* prompt_id = string_field "prompt_id" json in
  let* text = string_field "text" json in
  Ok { prompt_id; text }

let answer_response_to_json = function
  | Matched { answer; tier; balloons; miles } ->
      `Assoc
        [
          ("result", `String "match");
          ("answer", `String answer);
          ("tier", `String (tier_to_string tier));
          ("balloons", `Int balloons);
          ("miles", `Int miles);
        ]
  | No_match -> `Assoc [ ("result", `String "no_match") ]

let answer_response_of_json json =
  let* result = string_field "result" json in
  match result with
  | "no_match" -> Ok No_match
  | "match" -> (
      let* answer = string_field "answer" json in
      let* tier_s = string_field "tier" json in
      let* balloons = int_field "balloons" json in
      let* miles = int_field "miles" json in
      match tier_of_string tier_s with
      | Some tier -> Ok (Matched { answer; tier; balloons; miles })
      | None -> Error ("unknown tier \"" ^ tier_s ^ "\""))
  | other -> Error ("unknown result \"" ^ other ^ "\"")

let error_to_json msg = `Assoc [ ("error", `String msg) ]
