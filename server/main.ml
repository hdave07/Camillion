(* main.ml

   Owner: Teju (primary), Meira (secondary)

   Dream server for MS2. GET /api/round -> the round's prompts (ids and text,
   never answers) POST /api/answer -> raw text -> matched answer, tier,
   balloons, miles Also serves the page at /, files under /static/, and the
   compiled front end (/main.js = _build/default/web/main.bc.js).

   Run from the repo root with `make serve`, then open http://localhost:8080.
   For now the prompts come from Demo_round; see that file for what replaces it
   once Bank and Engine are merged. *)

open Camillion

let reply ?status json = Dream.json ?status (Yojson.Safe.to_string json)

let round_handler _request =
  let prompts =
    List.map
      (fun (p : Demo_round.prompt) -> { Api.id = p.id; text = p.text })
      Demo_round.prompts
  in
  reply (Api.round_response_to_json { Api.prompts })

(* Pure part of POST /api/answer: request JSON -> (status, response JSON). Kept
   separate from Dream so the logic is easy to follow and to test. *)
let answer_of_body body =
  match Yojson.Safe.from_string body with
  | exception Yojson.Json_error msg ->
      (`Bad_Request, Api.error_to_json ("invalid JSON: " ^ msg))
  | json -> (
      match Api.answer_request_of_json json with
      | Error msg -> (`Bad_Request, Api.error_to_json msg)
      | Ok { Api.prompt_id; text } -> (
          match Demo_round.find prompt_id with
          | None ->
              (`Not_Found, Api.error_to_json ("unknown prompt_id: " ^ prompt_id))
          | Some prompt -> (
              match Matcher.match_answer prompt.answers text with
              | None -> (`OK, Api.answer_response_to_json Api.No_match)
              | Some entry ->
                  let balloons, miles = Demo_round.score entry.tier in
                  ( `OK,
                    Api.answer_response_to_json
                      (Api.Matched
                         {
                           answer = entry.name;
                           tier = entry.tier;
                           balloons;
                           miles;
                         }) ))))

let answer_handler request =
  let open Lwt.Syntax in
  let* body = Dream.body request in
  let status, json = answer_of_body body in
  reply ~status json

let () =
  Dream.run ~port:8080 @@ Dream.logger
  @@ Dream.router
       [
         Dream.get "/" (Dream.from_filesystem "web/static" "index.html");
         Dream.get "/static/**" (Dream.static "web/static");
         Dream.get "/main.js"
           (Dream.from_filesystem "_build/default/web" "main.bc.js");
         Dream.get "/api/round" round_handler;
         Dream.post "/api/answer" answer_handler;
       ]
