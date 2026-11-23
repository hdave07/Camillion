(* engine.ml

   Owner: Saranya (primary), Teju (secondary)

   Implementation of Engine.

   See docs/ARCHITECTURE.md. No implementation yet. *)

type 'prompt t = { remaining : 'prompt list; altitude : int }

let pick_prompts ~seed ~count ~prompt_id prompts =
  let seen = Hashtbl.create (List.length prompts) in
  let distinct =
    List.filter
      (fun prompt ->
        let id = prompt_id prompt in
        if Hashtbl.mem seen id then false
        else (
          Hashtbl.add seen id ();
          true))
      prompts
    |> Array.of_list
  in
  let available = Array.length distinct in
  if count < 1 then Error "A round needs at least one prompt."
  else if count > available then
    Error
      (Printf.sprintf "Requested %d prompts, but only %d are available." count
         available)
  else
    let random = Random.State.make [| seed |] in
    for i = 0 to count - 1 do
      let j = i + Random.State.int random (available - i) in
      let prompt = distinct.(i) in
      distinct.(i) <- distinct.(j);
      distinct.(j) <- prompt
    done;
    Ok (Array.to_list (Array.sub distinct 0 count))

let start prompts = { remaining = prompts; altitude = 0 }

let current_prompt round =
  match round.remaining with [] -> None | prompt :: _ -> Some prompt

let altitude round = round.altitude

let submit ~elapsed_seconds ~matched_tier round =
  match round.remaining with
  | [] -> None
  | _ :: remaining ->
      let outcome =
        Scoring.classify_submission ~elapsed_seconds ~matched_tier
      in
      let altitude = round.altitude + Scoring.altitude_gain outcome in
      Some (outcome, { remaining; altitude })
