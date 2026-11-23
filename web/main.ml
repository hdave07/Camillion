(* main.ml

   Owner: Meira (primary), Saranya (secondary)

   Browser front end, compiled to JavaScript with Js_of_ocaml. It plays one
   round: a start screen, then for each prompt a 25-second countdown, an answer
   box and the camel rising in the scene, then a results screen with a share
   row.

   The browser holds no answers. It asks the server for the round (GET
   /api/round), sends each answer (POST /api/answer) and learns only the tier.
   Round state, scoring and the timeout rule come from the shared [Engine] and
   [Scoring] modules; the display helpers come from [Present]. Only DOM, timer
   and network code lives here. *)

open Js_of_ocaml
open Js_of_ocaml_lwt
open Camillion

let ( let* ) = Lwt.bind

(* ---------- DOM helpers ---------- *)

let by_id id = Dom_html.getElementById id
let set_html id html = (by_id id)##.innerHTML := Js.string html
let set_text id text = (by_id id)##.textContent := Js.some (Js.string text)

let set_style id css =
  (by_id id)##setAttribute (Js.string "style") (Js.string css)

(* Text that came from the server goes through [escape] before it is placed in
   an HTML template. *)
let escape s =
  let buf = Buffer.create (String.length s) in
  String.iter
    (function
      | '&' -> Buffer.add_string buf "&amp;"
      | '<' -> Buffer.add_string buf "&lt;"
      | '>' -> Buffer.add_string buf "&gt;"
      | '"' -> Buffer.add_string buf "&quot;"
      | '\'' -> Buffer.add_string buf "&#39;"
      | c -> Buffer.add_char buf c)
    s;
  Buffer.contents buf

let answer_input () =
  match Dom_html.getElementById_coerce "answer" Dom_html.CoerceTo.input with
  | Some input -> input
  | None -> failwith "missing #answer"

let answer_form () =
  match Dom_html.getElementById_coerce "answer-form" Dom_html.CoerceTo.form with
  | Some form -> form
  | None -> failwith "missing #answer-form"

let set_form_enabled enabled =
  (answer_input ())##.disabled := Js.bool (not enabled);
  match Dom_html.getElementById_coerce "submit" Dom_html.CoerceTo.button with
  | Some button -> button##.disabled := Js.bool (not enabled)
  | None -> ()

(* Seconds since the epoch, from the browser's clock. *)
let now () = Js.to_float (new%js Js.date_now)##getTime /. 1000.

(* ---------- Talking to the server ---------- *)

let unreachable = "Could not reach the server. Is it running?"

(* The server reports problems as {"error": "..."}. *)
let error_message ~code content =
  let fallback = Printf.sprintf "The server answered with status %d." code in
  match Yojson.Safe.from_string content with
  | `Assoc fields -> (
      match List.assoc_opt "error" fields with
      | Some (`String message) -> message
      | _ -> fallback)
  | _ -> fallback
  | exception Yojson.Json_error _ -> fallback

(* [request ?body url] is the response body of a GET (no [body]) or a POST of
   the JSON text [body], or an error message for the player. *)
let request ?body url =
  Lwt.catch
    (fun () ->
      let* frame =
        match body with
        | None -> XmlHttpRequest.perform_raw_url url
        | Some json ->
            XmlHttpRequest.perform_raw_url
              ~headers:[ ("Content-Type", "application/json") ]
              ~contents:(`String json) ~override_method:`POST url
      in
      let code = frame.XmlHttpRequest.code in
      let content = frame.XmlHttpRequest.content in
      if code = 200 then Lwt.return (Ok content)
      else if code = 0 then Lwt.return (Error unreachable)
      else Lwt.return (Error (error_message ~code content)))
    (fun _ -> Lwt.return (Error unreachable))

let parse_json content =
  match Yojson.Safe.from_string content with
  | json -> Ok json
  | exception Yojson.Json_error msg ->
      Error ("The server sent something unexpected: " ^ msg)

let load_round () =
  let* response = request "/api/round" in
  Lwt.return
    (Result.bind response (fun content ->
         Result.bind (parse_json content) (fun json ->
             Result.map
               (fun (round : Api.round_response) -> round.prompts)
               (Api.round_response_of_json json))))

let post_answer ~prompt_id ~text =
  let body =
    Yojson.Safe.to_string (Api.answer_request_to_json { Api.prompt_id; text })
  in
  let* response = request ~body "/api/answer" in
  Lwt.return
    (Result.bind response (fun content ->
         Result.bind (parse_json content) Api.answer_response_of_json))

(* ---------- The scene: sky, camel and balloons ---------- *)

(* How far the camel can rise inside the scene, in pixels. *)
let max_rise_px = 190.

let scene_html =
  {|<section id="scene" aria-label="The camel and its balloons">
  <div id="stars"></div>
  <div id="clouds">
    <div class="cloud cloud-a"></div>
    <div class="cloud cloud-b"></div>
  </div>
  <div id="camel-group">
    <div id="balloons" aria-hidden="true"></div>
    <div id="camel" role="img" aria-label="A camel">&#x1F42A;</div>
  </div>
  <div id="dunes" class="dunes"></div>
  <div id="readout">0 miles</div>
</section>|}

let update_scene ~max_miles ~miles ~balloons =
  (* How high the camel sits depends on the share of the round's best possible
     total; the backdrop depends on absolute miles, so one very rare answer is
     enough to leave the ground behind or reach space. *)
  let fraction = Present.altitude_fraction ~max_miles miles in
  let level = Present.scene_level miles in
  set_style "scene" ("background:" ^ Present.sky_colour level);
  set_style "camel-group"
    (Printf.sprintf "transform:translateY(-%dpx)"
       (int_of_float (fraction *. max_rise_px)));
  set_style "stars"
    (Printf.sprintf "opacity:%.2f" (Float.max 0. ((level -. 0.6) /. 0.4)));
  set_style "clouds"
    (Printf.sprintf "opacity:%.2f"
       (Float.min 1. (Float.max 0. ((0.9 -. level) /. 0.2))));
  let ground = Present.ground_visibility miles in
  set_style "dunes"
    (Printf.sprintf "opacity:%.2f;transform:translateY(%dpx)" ground
       (int_of_float ((1. -. ground) *. 120.)));
  set_text "balloons" (Present.balloon_row balloons);
  set_text "readout"
    (Printf.sprintf "%d miles \u{00B7} %s" miles (Present.zone_name miles))

(* ---------- Screens ---------- *)

let start_screen_html =
  {|<main class="card">
  <h1>&#x1F42A; Camillion</h1>
  <p class="lede">The rarest valid answer wins. Answer each prompt before the
  clock runs out: the rarer your answer, the more balloons lift your camel.</p>
  <button id="start" class="primary">Start</button>
  <p id="start-status" class="status" aria-live="polite"></p>
</main>|}

let round_screen_html =
  {|<main class="game">
  <header>
    <h1>&#x1F42A; Camillion</h1>
    <p id="progress"></p>
  </header>|}
  ^ scene_html
  ^ {|<section class="panel">
    <h2 id="prompt"></h2>
    <div class="timer"><div id="timer-bar"></div></div>
    <p id="timer-text"></p>
    <form id="answer-form" autocomplete="off">
      <input id="answer" type="text" placeholder="Type your answer"
        autocapitalize="off" spellcheck="false" />
      <button id="submit" class="primary" type="submit">Lift off</button>
    </form>
    <div id="feedback" aria-live="polite"></div>
  </section>
</main>|}

let draw_timer ~elapsed =
  let limit = Scoring.time_limit_seconds in
  let remaining = Float.max 0. (limit -. elapsed) in
  let colour = if remaining <= 5. then "#c8472b" else "#2f7d6d" in
  set_style "timer-bar"
    (Printf.sprintf "width:%.1f%%;background:%s"
       (100. *. remaining /. limit)
       colour);
  set_text "timer-text" (Printf.sprintf "%d s" (int_of_float (ceil remaining)))

type reply =
  | Typed of string * float  (** the answer text and seconds taken *)
  | Out_of_time

(* Resolves once the full time limit has passed. *)
let rec countdown ~start =
  let elapsed = now () -. start in
  if elapsed >= Scoring.time_limit_seconds then (
    draw_timer ~elapsed:Scoring.time_limit_seconds;
    Lwt.return Out_of_time)
  else (
    draw_timer ~elapsed;
    let* () = Lwt_js.sleep 0.1 in
    countdown ~start)

(* Resolves when the player submits a non-blank answer. *)
let rec wait_for_answer ~start =
  let* event = Lwt_js_events.submit (answer_form ()) in
  Dom.preventDefault event;
  let text = String.trim (Js.to_string (answer_input ())##.value) in
  if text = "" then wait_for_answer ~start
  else Lwt.return (Typed (text, now () -. start))

(* Whichever finishes first wins; [Lwt.pick] cancels the other. *)
let ask ~start = Lwt.pick [ countdown ~start; wait_for_answer ~start ]
let show_feedback html = set_html "feedback" html

let outcome_html ~answer ~balloons = function
  | Scoring.Correct tier ->
      Printf.sprintf
        {|<p class="result tier-%s"><strong>%s</strong> &mdash; %s<br />
        +%d miles &middot; +%d balloons</p>|}
        (Api.tier_to_string tier) (escape answer)
        (escape (Present.tier_label tier))
        (Scoring.miles_for_tier tier)
        balloons
  | Scoring.Incorrect ->
      {|<p class="result miss">Not on our list for this prompt. +0 miles</p>|}
  | Scoring.Timed_out ->
      {|<p class="result miss">Time&rsquo;s up! +0 miles</p>|}

(* Sends one answer, offering a retry if the server cannot be reached. The
   seconds already taken stay fixed, so a failed request costs no time. *)
let rec check_answer (prompt : Api.prompt_view) text =
  show_feedback {|<p class="status">Checking&hellip;</p>|};
  let* result = post_answer ~prompt_id:prompt.id ~text in
  match result with
  | Ok response -> Lwt.return response
  | Error message ->
      show_feedback
        (Printf.sprintf
           {|<p class="result miss">%s</p>
             <button id="retry" class="primary">Try again</button>|}
           (escape message));
      let* _ = Lwt_js_events.click (by_id "retry") in
      check_answer prompt text

(* Plays the prompts one at a time. [balloons] is the total shown on the camel
   and [outcomes] the results so far, latest first. *)
let rec play ~total ~max_miles ~balloons ~outcomes round =
  match Engine.current_prompt round with
  | None -> Lwt.return (round, List.rev outcomes)
  | Some (prompt : Api.prompt_view) -> (
      set_text "progress"
        (Printf.sprintf "Prompt %d of %d" (List.length outcomes + 1) total);
      set_text "prompt" prompt.Api.text;
      show_feedback "";
      (answer_input ())##.value := Js.string "";
      set_form_enabled true;
      (answer_input ())##focus;
      let start = now () in
      (* A miss does not end the prompt: the player may try again, and the clock
         keeps running from [start]. A match or the timeout ends it. *)
      let rec attempt () =
        let* reply = ask ~start in
        set_form_enabled false;
        match reply with
        | Out_of_time -> Lwt.return (Scoring.time_limit_seconds, None, "", 0)
        | Typed (text, elapsed) -> (
            let* response = check_answer prompt text in
            match response with
            | Api.Matched { answer; tier; balloons = gained; _ } ->
                Lwt.return (elapsed, Some tier, answer, gained)
            | Api.No_match ->
                show_feedback
                  (Printf.sprintf
                     {|<p class="result miss">&ldquo;%s&rdquo; is not on our list. Try another answer!</p>|}
                     (escape text));
                (answer_input ())##.value := Js.string "";
                set_form_enabled true;
                (answer_input ())##focus;
                attempt ())
      in
      let* elapsed_seconds, matched_tier, answer, gained = attempt () in
      match Engine.submit ~elapsed_seconds ~matched_tier round with
      | None -> Lwt.return (round, List.rev outcomes)
      | Some (outcome, round) ->
          let balloons = balloons + gained in
          update_scene ~max_miles ~miles:(Engine.altitude round) ~balloons;
          let next_label =
            if Engine.current_prompt round = None then "See results"
            else "Next prompt"
          in
          show_feedback
            (outcome_html ~answer ~balloons:gained outcome
            ^ Printf.sprintf {|<button id="next" class="primary">%s</button>|}
                next_label);
          let* _ = Lwt_js_events.click (by_id "next") in
          play ~total ~max_miles ~balloons ~outcomes:(outcome :: outcomes) round
      )

let results_html ~altitude ~outcomes =
  Printf.sprintf
    {|<h3>Final altitude: %d miles</h3>
      <pre id="share">%s</pre>
      <button id="again" class="primary">Play again</button>|}
    altitude
    (escape (Present.share_text ~altitude outcomes))

(* Waits for a click on Start, then loads the round, showing any problem and
   waiting for another click until the prompts arrive. *)
let rec choose_round () =
  let* _ = Lwt_js_events.click (by_id "start") in
  set_text "start-status" "Loading the prompts\xe2\x80\xa6";
  let* loaded = load_round () in
  match loaded with
  | Ok (_ :: _ as prompts) -> Lwt.return prompts
  | Ok [] ->
      set_text "start-status" "The server has no prompts yet.";
      choose_round ()
  | Error message ->
      set_text "start-status" message;
      set_text "start" "Try again";
      choose_round ()

let rec start_screen () =
  set_html "app" start_screen_html;
  let* prompts = choose_round () in
  play_round prompts

and play_round prompts =
  let total = List.length prompts in
  let max_miles = total * Scoring.miles_for_tier Tier.Interstellar in
  set_html "app" round_screen_html;
  update_scene ~max_miles ~miles:0 ~balloons:0;
  let* round, outcomes =
    play ~total ~max_miles ~balloons:0 ~outcomes:[] (Engine.start prompts)
  in
  set_text "progress" "Round complete";
  set_text "prompt" "Your flight";
  set_html "feedback" (results_html ~altitude:(Engine.altitude round) ~outcomes);
  let* _ = Lwt_js_events.click (by_id "again") in
  start_screen ()

let () = Lwt.async start_screen
