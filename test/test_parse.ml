(* test_parse.ml

   Owner: Harini

   OUnit tests for the scraper's Parse module, on small hand-written HTML
   tables shaped like Wikipedia's. Expected answers were worked out by hand
   from each table. *)

open OUnit2
open Scraper

(** [link title text] is an article link to [title] showing [text], in the
    format Wikipedia's HTML uses. *)
let link (title : string) (text : string) : string =
  Printf.sprintf {|<a rel="mw:WikiLink" title="%s">%s</a>|} title text

(** [table rows] is a [wikitable] containing the HTML rows [rows]. *)
let table (rows : string list) : string =
  {|<table class="wikitable">|} ^ String.concat "" rows ^ "</table>"

(** [header] is a header row: only [<th>] cells, with a link that must not be
    taken as an answer. *)
let header =
  "<tr><th>Number</th><th>Symbol</th><th>" ^ link "Name" "Name" ^ "</th></tr>"

(** [element_row n symbol name] is a data row like the elements table, with the
    answer link in column 2. *)
let element_row (n : int) (symbol : string) (name : string) : string =
  Printf.sprintf "<tr><td>%d</td><td>%s</td><td>%s</td></tr>" n symbol
    (link name name)

(** [table_at_2 html] is the result of extracting column 2 of the first
    wikitable in [html]. *)
let table_at_2 (html : string) : (Parse.candidate list, string) result =
  Parse.extract (Config.Table { index = 0; column = 2 }) html

(** [pairs result] is [Ok] of the [(name, wiki_title)] pairs in [result], so
    results can be compared and printed easily. *)
let pairs (result : (Parse.candidate list, string) result) :
    ((string * string) list, string) result =
  Result.map
    (List.map (fun (c : Parse.candidate) -> (c.name, c.wiki_title)))
    result

(** [show r] is a readable form of [r] for failure messages. *)
let show (r : ((string * string) list, string) result) : string =
  match r with
  | Ok ps ->
      "Ok ["
      ^ String.concat "; " (List.map (fun (n, t) -> n ^ " | " ^ t) ps)
      ^ "]"
  | Error msg -> "Error " ^ msg

(** [check expected html] asserts that extracting column 2 of the first
    wikitable in [html] gives the [(name, wiki_title)] pairs [expected]. *)
let check (expected : (string * string) list) (html : string) : unit =
  assert_equal ~printer:show (Ok expected) (pairs (table_at_2 html))

(** [is_error r] is [true] iff [r] is an [Error]. *)
let is_error (r : ('a, 'b) result) : bool = Result.is_error r

let test_basic_table _ =
  check
    [ ("Hydrogen", "Hydrogen"); ("Helium", "Helium") ]
    (table
       [ header; element_row 1 "H" "Hydrogen"; element_row 2 "He" "Helium" ])

let test_footnote_ignored _ =
  let row =
    "<tr><td>8</td><td>O</td><td>" ^ link "Oxygen" "Oxygen"
    ^ {|<sup><a href="#cite_note-1">[1]</a></sup></td></tr>|}
  in
  check [ ("Oxygen", "Oxygen") ] (table [ header; row ])

let test_file_link_skipped _ =
  let row =
    "<tr><td>2</td><td>He</td><td>" ^ link "File:He.png" "img" ^ " "
    ^ link "Helium" "Helium" ^ "</td></tr>"
  in
  check [ ("Helium", "Helium") ] (table [ header; row ])

let test_text_differs_from_title _ =
  let row =
    "<tr><td>1</td><td>x</td><td>"
    ^ link "P.S. I Love You (Beatles song)" "P.S. I Love You"
    ^ "</td></tr>"
  in
  check
    [ ("P.S. I Love You", "P.S. I Love You (Beatles song)") ]
    (table [ header; row ])

let test_th_cell_counts_as_column _ =
  (* Like the Beatles table: the song is a <th> row header in column 0. *)
  let row =
    "<tr><th>" ^ link "Help!" "Help!" ^ "</th><td>Help!</td><td>1965</td></tr>"
  in
  let result =
    Parse.extract (Config.Table { index = 0; column = 0 }) (table [ row ])
  in
  assert_equal ~printer:show (Ok [ ("Help!", "Help!") ]) (pairs result)

let test_duplicates_removed _ =
  let again =
    "<tr><td>1</td><td>H</td><td>" ^ link "Hydrogen" "H2" ^ "</td></tr>"
  in
  check
    [ ("Hydrogen", "Hydrogen"); ("Helium", "Helium") ]
    (table
       [
         header;
         element_row 1 "H" "Hydrogen";
         again;
         element_row 2 "He" "Helium";
       ])

let test_rows_without_answer_skipped _ =
  let no_link = "<tr><td>9</td><td>?</td><td>Nothing here</td></tr>" in
  let short_row = "<tr><td>only one cell</td></tr>" in
  check
    [ ("Hydrogen", "Hydrogen") ]
    (table [ header; no_link; short_row; element_row 1 "H" "Hydrogen" ])

let test_index_picks_wikitable _ =
  (* A table without class wikitable is not counted. *)
  let html =
    "<table>"
    ^ element_row 1 "X" "Not an answer"
    ^ "</table>"
    ^ table [ element_row 1 "H" "Hydrogen" ]
    ^ table [ element_row 2 "He" "Helium" ]
  in
  let result = Parse.extract (Config.Table { index = 1; column = 2 }) html in
  assert_equal ~printer:show (Ok [ ("Helium", "Helium") ]) (pairs result)

let test_missing_table_is_error _ =
  let html = table [ element_row 1 "H" "Hydrogen" ] in
  let result = Parse.extract (Config.Table { index = 1; column = 2 }) html in
  assert_bool "index past the last wikitable" (is_error result);
  assert_bool "page with no tables" (is_error (table_at_2 "<p>hi</p>"))

let test_no_answers_is_error _ =
  (* Column 0 holds numbers, not links. *)
  let html = table [ header; element_row 1 "H" "Hydrogen" ] in
  let result = Parse.extract (Config.Table { index = 0; column = 0 }) html in
  assert_bool "no links in column 0" (is_error result)

let suite =
  "parse"
  >::: [
         "basic table, header skipped" >:: test_basic_table;
         "footnote ignored" >:: test_footnote_ignored;
         "File: link skipped" >:: test_file_link_skipped;
         "link text differs from title" >:: test_text_differs_from_title;
         "th cell counts as a column" >:: test_th_cell_counts_as_column;
         "duplicates removed" >:: test_duplicates_removed;
         "rows without an answer skipped" >:: test_rows_without_answer_skipped;
         "index picks the right wikitable" >:: test_index_picks_wikitable;
         "missing table is an error" >:: test_missing_table_is_error;
         "no answers is an error" >:: test_no_answers_is_error;
       ]
