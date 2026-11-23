(* parse.ml
   Turns a Wikipedia list page's HTML into candidate answers. Pure: no network
   or file IO. *)

open Soup

(** A candidate answer found on a list page. *)
type candidate = {
  (* the link's text, e.g. "P.S. I Love You"; becomes the canonical answer *)
  name : string;
  (* the article title, e.g. "P.S. I Love You (Beatles song)"; used for API
     calls *)
  wiki_title : string;
}

(** [is_data_row row] is [true] iff [row] contains at least one [<td>] cell.
    Header rows contain only [<th>] cells, so they return [false]. *)
let is_data_row (row : element node) : bool = Option.is_some (row $? "td")

(** [cell_at column row] is the cell at position [column] (counting from 0) in
    [row], counting both [<td>] and [<th>] cells, or [None] if [row] has fewer
    cells. Requires: [column >= 0]. *)
let cell_at (column : int) (row : element node) : element node option =
  let cells = row |> children |> elements |> to_list in
  (*retunrs the element at position column in cells as Option*)
  List.nth_opt cells column

(** [candidate_of_link link] is the candidate for the article link [link], or
    [None] if [link] has no [title], its title contains [':'] (a File:,
    Category:, Help:, ... page), or its text is empty. *)
let candidate_of_link (link : element node) : candidate option =
  let name = texts link |> String.concat "" |> String.trim in
  match attribute "title" link with
  | Some title when name <> "" && not (String.contains title ':') ->
      Some { name; wiki_title = title }
  | _ -> None

(** [candidate_of_cell cell] is the candidate for the first valid article link
    (one with [rel="mw:WikiLink"]) in [cell], or [None] if it has none. *)
let candidate_of_cell (cell : element node) : candidate option =
  let links = to_list (cell $$ "a[rel=\"mw:WikiLink\"]") in
  List.find_map candidate_of_link links

(** [dedupe cs] is [cs] without the candidates whose [wiki_title] already
    appeared earlier in [cs]. The first occurrence is kept and the order is
    preserved. *)
let dedupe (cs : candidate list) : candidate list =
  let rec go seen = function
    | [] -> []
    | c :: rest ->
        if List.mem c.wiki_title seen then go seen rest
        else c :: go (c.wiki_title :: seen) rest
  in
  go [] cs

(** [candidate_of_row column row] is the candidate in the cell at position
    [column] of [row], or [None] if that cell does not exist or has no valid
    article link. Requires: [column >= 0]. *)
let candidate_of_row (column : int) (row : element node) : candidate option =
  match cell_at column row with
  | None -> None
  | Some cell -> candidate_of_cell cell

(** [extract extractor html] is [Ok cs], where [cs] are the candidate answers
    that [extractor] finds in the page [html], in page order and without
    duplicates. It is [Error msg] if the table [extractor] names does not exist
    or no answers are found (e.g. because a page edit moved the table).
    Requires: [index >= 0] and [column >= 0]. *)
let extract (extractor : Config.extractor) (html : string) :
    (candidate list, string) result =
  match extractor with
  | Table { index; column } -> (
      let tables = to_list (parse html $$ "table.wikitable") in
      match List.nth_opt tables index with
      | None ->
          Error
            (Printf.sprintf "no wikitable at index %d (page has %d)" index
               (List.length tables))
      | Some table -> (
          (*find all tables with tr*)
          let rows = to_list (table $$ "tr") in
          (*keep if its a data row so no header*)
          let data_rows = List.filter is_data_row rows in
          (*for each row, get the value inside the Some convert to candidate and drop any None elements*)
          let candidates =
            List.filter_map (candidate_of_row column) data_rows
          in
          match dedupe candidates with
          | [] ->
              Error
                (Printf.sprintf "no answers in wikitable %d, column %d" index
                   column)
          | answers -> Ok answers))
