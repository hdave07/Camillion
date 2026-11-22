(* api.mli

   Owner: Teju (primary), Meira (secondary)

   Shared contract between server/ and web/: the request and response types of
   the two MS2 endpoints and their JSON conversion. Both sides use these
   functions, so the JSON shape is defined in exactly one place.

   GET /api/round response: {"prompts": [{"id": "africa", "text": "Name a
   country in Africa"}]}

   POST /api/answer request: {"prompt_id": "africa", "text": "<raw player
   input>"} response: {"result": "match", "answer": "Chad", "tier": "updraft",
   "balloons": 3, "miles": 16} or: {"result": "no_match"} errors: HTTP 400 (bad
   JSON) or 404 (unknown prompt_id) with {"error": "<message>"} *)

type prompt_view = {
  id : string;
  text : string;
}
(** What the browser sees of a prompt: never its answers. *)

type round_response = { prompts : prompt_view list }

type answer_request = {
  prompt_id : string;
  text : string;
}
(** [text] is the player's raw input; the server normalizes it. *)

type answer_response =
  | Matched of {
      answer : string;
      tier : Tier.t;
      balloons : int;
      miles : int;
    }  (** [answer] is the canonical name, e.g. "United States" for "usa". *)
  | No_match

val tier_to_string : Tier.t -> string
(** "sand", "breeze", "updraft", "jet_stream", "one_in_a_camillion",
    "interstellar". *)

val tier_of_string : string -> Tier.t option
(** Inverse of {!tier_to_string}; [None] for any other string. *)

val round_response_to_json : round_response -> Yojson.Safe.t
val round_response_of_json : Yojson.Safe.t -> (round_response, string) result
val answer_request_to_json : answer_request -> Yojson.Safe.t

val answer_request_of_json : Yojson.Safe.t -> (answer_request, string) result
(** [Error msg] if a field is missing or has the wrong type. *)

val answer_response_to_json : answer_response -> Yojson.Safe.t
val answer_response_of_json : Yojson.Safe.t -> (answer_response, string) result
val error_to_json : string -> Yojson.Safe.t
