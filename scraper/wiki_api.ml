(* wiki_api.ml
   Asks Wikipedia's APIs about answer titles: redirects (for aliases) and page
   views (for tiers). Downloads go through [Fetch], so responses are cached. *)

open Yojson.Basic.Util

(** [batch_size] is the most titles one MediaWiki API request may ask about. *)
let batch_size = 50

(** [batches n xs] splits [xs] into lists of [n] elements each, in order. The
    last list may be shorter. [batches n []] is [[]]. Requires: [n > 0]. *)
let rec batches (n : int) (xs : 'a list) : 'a list list =
  match xs with [] -> [] | _ -> List.take n xs :: batches n (List.drop n xs)

(** [redirects_url continue titles] is the MediaWiki API URL that asks for every
    redirect to each article in [titles]. With [redirects=1], a title that is
    itself a redirect is first followed to its real article. Section redirects
    are left out ([rdshow=!fragment]). [continue] is extra parameters copied
    from the previous response's ["continue"] object, or [[]] for the first
    request. Requires: [titles] has between 1 and [batch_size] elements. *)
let redirects_url (continue : (string * string) list) (titles : string list) :
    string =
  let base = Uri.of_string "https://en.wikipedia.org/w/api.php" in
  let params =
    [
      ("action", "query");
      ("prop", "redirects");
      ("titles", String.concat "|" titles);
      ("redirects", "1");
      ("rdlimit", "max");
      ("rdshow", "!fragment");
      ("format", "json");
      ("formatversion", "2");
    ]
    @ continue
  in
  Uri.to_string (Uri.with_query' base params)

(** [title_fixes json] is the list of [(from, to)] title pairs in the MediaWiki
    response [json]: titles the API rewrote into standard form ([normalized])
    and titles that were redirects and were followed to their real article
    ([redirects]). Raises: [Type_error] if [json] is not a query response. *)
let title_fixes (json : Yojson.Basic.t) : (string * string) list =
  let query = member "query" json in
  let pair (fix : Yojson.Basic.t) : string * string =
    (to_string (member "from" fix), to_string (member "to" fix))
  in
  let pairs_under (key : string) : (string * string) list =
    match member key query with `List fixes -> List.map pair fixes | _ -> []
  in
  pairs_under "normalized" @ pairs_under "redirects"

(** [redirect_titles page] is the titles of the redirects listed for [page] in
    one response, or [[]] if this response lists none for it. Raises:
    [Type_error] if [page] is not a page object. *)
let redirect_titles (page : Yojson.Basic.t) : string list =
  match member "redirects" page with
  | `List redirects ->
      List.map (fun redirect -> to_string (member "title" redirect)) redirects
  | _ -> []

(** [page_redirects json] is [(title, redirects)] for each page in the MediaWiki
    response [json], where [redirects] is [redirect_titles] of that page.
    Raises: [Type_error] if [json] is not a query response. *)
let page_redirects (json : Yojson.Basic.t) : (string * string list) list =
  let pages = to_list (member "pages" (member "query" json)) in
  List.map
    (fun page -> (to_string (member "title" page), redirect_titles page))
    pages

(** [continue_params json] is [Some params] if the MediaWiki response [json] has
    a ["continue"] object, meaning more results remain, where [params] are its
    key/value pairs to send with the next request. It is [None] if [json] is the
    last response. Raises: [Type_error] if a value in ["continue"] is not a
    string. *)
let continue_params (json : Yojson.Basic.t) : (string * string) list option =
  match member "continue" json with
  | `Assoc fields ->
      Some (List.map (fun (key, value) -> (key, to_string value)) fields)
  | _ -> None

(** What the redirects API said about one batch of titles, collected from all of
    its responses. *)
type redirect_info = {
  (* [(from, to)] title pairs, see [title_fixes] *)
  fixes : (string * string) list;
  (* [(title, redirects)] for each page, see [page_redirects]. A page appears
     once per response, so its redirects can be spread over several entries. *)
  pages : (string * string list) list;
}

(** [read_response body] is [Ok (info, next)] where [info] is the title fixes
    and page redirects in the MediaWiki response [body], and [next] is
    [continue_params] of it. It is [Error msg] if [body] is not valid JSON or
    not a query response. *)
let read_response (body : string) :
    (redirect_info * (string * string) list option, string) result =
  try
    let json = Yojson.Basic.from_string body in
    let info = { fixes = title_fixes json; pages = page_redirects json } in
    Ok (info, continue_params json)
  with Yojson.Json_error msg | Type_error (msg, _) ->
    Error ("unexpected redirects API response: " ^ msg)

(** [fetch_redirects titles] is a promise of [Ok info], where [info] is
    everything the redirects API says about [titles], following ["continue"]
    until the last response. It is [Error msg] if any request fails or any
    response cannot be read. Requires: [titles] has between 1 and [batch_size]
    elements. *)
let fetch_redirects (titles : string list) :
    (redirect_info, string) result Lwt.t =
  let rec loop continue so_far =
    match%lwt Fetch.fetch (redirects_url continue titles) with
    | Error msg -> Lwt.return (Error msg)
    | Ok body -> (
        match read_response body with
        | Error msg -> Lwt.return (Error msg)
        | Ok (info, next) -> (
            let so_far =
              {
                fixes = so_far.fixes @ info.fixes;
                pages = so_far.pages @ info.pages;
              }
            in
            match next with
            | None -> Lwt.return (Ok so_far)
            | Some next_continue -> loop next_continue so_far))
  in
  loop [] { fixes = []; pages = [] }
