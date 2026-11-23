(* bank.ml

   Owner: Roma (primary), Harini (secondary)

   Implementation of Bank.

   See docs/ARCHITECTURE.md. *)

type answer = {
  canonical : string;
  aliases : string list;
  tier : Tier.t;
}

type prompt = {
  id : string;
  text : string;
  answers : answer list;
}

type error = {
  location : string;
  message : string;
}

(** [get_string json field] recieves a JSON object and a field name, such as
    "id". It tries finding the field name in the JSON. If its finds the field,
    then it returns the string value associated with the field, otherwise it
    returns None if there is no value or if the field doesn't exist. *)
let get_string (json : Yojson.Basic.t) (field : string) : string option =
  match json with
  | `Assoc fields -> (
      match List.assoc_opt field fields with
      | Some (`String value) -> Some value
      | _ -> None)
  | _ -> None

(** [get_string_list json field] recieves a JSON object and a field name, such
    as "alias". This helper is meant for string lists. Takes a JSON field and
    returns it as an OCaml option string list. It returns None if the field is
    missing. Note that "Some []" is a valid field value, for an empty alias
    list.*)
let get_string_list (json : Yojson.Basic.t) (field : string) :
    string list option =
  match json with
  | `Assoc fields -> (
      match List.assoc_opt field fields with
      | Some (`List values) ->
          let rec collect_strings values =
            match values with
            | [] -> Some []
            | `String value :: rest -> (
                match collect_strings rest with
                | Some strings -> Some (value :: strings)
                | None -> None)
            | _ -> None
          in
          collect_strings values
      | _ -> None)
  | _ -> None

(** [json_to_tier field] converts the JSON fields names into option constructor
    values from tier.ml*)
let json_to_tier (field : string) : Tier.t option =
  match field with
  | "Sand" -> Some Tier.Sand
  | "Breeze" -> Some Tier.Breeze
  | "Updraft" -> Some Tier.Updraft
  | "JetStream" -> Some Tier.JetStream
  | "OneInACamillion" -> Some Tier.OneInACamillion
  | "Interstellar" -> Some Tier.Interstellar
  | _ -> None

(** [parse_answer json] converts a JSON object into an answer record. Returns an
    error if any required field is missing or invalid. *)
let parse_answer (json : Yojson.Basic.t) : (answer, string) result =
  match
    ( get_string json "canonical",
      get_string_list json "aliases",
      get_string json "tier" )
  with
  | Some canonical, Some aliases, Some tier_name -> (
      match json_to_tier tier_name with
      | Some tier -> Ok { canonical; aliases; tier }
      | None -> Error "Unrecognized tier")
  | _ -> Error "Missing or invalid answer field"

(** [parse_prompt json location] converts a JSON object into a prompt. Invalid
    answers are skipped and reported as errors. Returns [None] if the prompt
    itself is invalid or has no valid answers. *)
let parse_prompt (json : Yojson.Basic.t) (location : string) :
    prompt option * error list =
  match (get_string json "id", get_string json "text", json) with
  | Some id, Some text, `Assoc fields -> (
      match List.assoc_opt "answers" fields with
      | Some (`List answer_jsons) ->
          let rec parse_answers remaining index valid_answers errors =
            match remaining with
            | [] -> (List.rev valid_answers, List.rev errors)
            | answer_json :: rest -> (
                match parse_answer answer_json with
                | Ok answer ->
                    parse_answers rest (index + 1) (answer :: valid_answers)
                      errors
                | Error message ->
                    let answer_error =
                      {
                        location =
                          location ^ ".answers[" ^ string_of_int index ^ "]";
                        message;
                      }
                    in
                    parse_answers rest (index + 1) valid_answers
                      (answer_error :: errors))
          in
          let answers, answer_errors = parse_answers answer_jsons 0 [] [] in
          if answers = [] then
            ( None,
              answer_errors
              @ [ { location; message = "Prompt has no valid answers" } ] )
          else (Some { id; text; answers }, answer_errors)
      | _ ->
          (None, [ { location; message = "Missing or invalid answers field" } ])
      )
  | _ ->
      (None, [ { location; message = "Missing or invalid prompt id or text" } ])

(** [load json] loads all valid prompts from a JSON bank. Returns the valid
    prompts and any errors encountered. *)
let load (json : Yojson.Basic.t) : prompt list * error list =
  match json with
  | `List prompt_jsons ->
      let rec parse_prompts remaining index valid_prompts errors =
        match remaining with
        | [] -> (List.rev valid_prompts, List.rev errors)
        | prompt_json :: rest -> (
            let location = "prompts[" ^ string_of_int index ^ "]" in
            let prompt, prompt_errors = parse_prompt prompt_json location in
            match prompt with
            | Some valid_prompt ->
                parse_prompts rest (index + 1)
                  (valid_prompt :: valid_prompts)
                  (List.rev_append prompt_errors errors)
            | None ->
                parse_prompts rest (index + 1) valid_prompts
                  (List.rev_append prompt_errors errors))
      in
      parse_prompts prompt_jsons 0 [] []
  | _ -> ([], [ { location = "root"; message = "Expected a list of prompts" } ])
