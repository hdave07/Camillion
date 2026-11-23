(* matcher.ml

   Owner: Teju (primary), Meira (secondary)

   Implementation of Matcher. *)

type entry = {
  name : string;
  aliases : string list;
  tier : Tier.t;
}

let edit_distance a b =
  let la = String.length a and lb = String.length b in
  (* d.(i).(j) = distance between the first i chars of a and first j of b *)
  let d = Array.make_matrix (la + 1) (lb + 1) 0 in
  for i = 0 to la do
    d.(i).(0) <- i
  done;
  for j = 0 to lb do
    d.(0).(j) <- j
  done;
  for i = 1 to la do
    for j = 1 to lb do
      let cost = if a.[i - 1] = b.[j - 1] then 0 else 1 in
      let best =
        min
          (d.(i - 1).(j) + 1)
          (min (d.(i).(j - 1) + 1) (d.(i - 1).(j - 1) + cost))
      in
      let best =
        if i > 1 && j > 1 && a.[i - 1] = b.[j - 2] && a.[i - 2] = b.[j - 1] then
          min best (d.(i - 2).(j - 2) + 1)
        else best
      in
      d.(i).(j) <- best
    done
  done;
  d.(la).(lb)

let max_typos key =
  let n = String.length key in
  if n <= 4 then 0 else if n <= 8 then 1 else 2

(* Normalized name and aliases of an entry, without empty strings. *)
let keys e =
  List.map Normalizer.normalize (e.name :: e.aliases)
  |> List.filter (fun k -> k <> "")

(* Smallest accepted distance from [input] to any key of [e], if any. *)
let fuzzy_distance input e =
  List.fold_left
    (fun acc k ->
      let dist = edit_distance input k in
      if dist > max_typos k then acc
      else
        match acc with
        | Some best when best <= dist -> acc
        | _ -> Some dist)
    None (keys e)

let match_answer entries raw =
  let input = Normalizer.normalize raw in
  if input = "" then None
  else
    match List.find_opt (fun e -> List.mem input (keys e)) entries with
    | Some e -> Some e
    | None -> (
        let candidates =
          List.filter_map
            (fun e ->
              match fuzzy_distance input e with
              | Some dist -> Some (dist, e)
              | None -> None)
            entries
          |> List.stable_sort (fun (d1, _) (d2, _) -> compare d1 d2)
        in
        match candidates with
        | [] -> None
        | [ (_, e) ] -> Some e
        | (d1, e) :: (d2, _) :: _ -> if d1 < d2 then Some e else None)
