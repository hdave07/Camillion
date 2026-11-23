(* The prompts the built by scraper, and where on Wikipedia each one's answers
   come from. To add a prompt, add a record to [sources]; no other code should
   need change *)

(** [extractor] describes how to find the answers on a Wikipedia page.

    Only [Table] exists for MS2. Other page layouts can be supported later by
    adding a case (ex. [Selector of string] for bullet lists,
    [Category of string] article in Wikipedia category). The compiler will then
    point to every [match] that must handle the new case. *)
type extractor =
  | Table of {
      (* [index] is which [table.wikitable] on the page holds the answers,
         counting from 0 in page order. *)
      index : int;
      (* [column] is which cell of each row holds the answer link, counting from
         0. Both [<td>] and [<th>] cells count. Header rows (rows with no
         [<td>]) are skipped. *)
      column : int;
    }

type source = {
  (* [id] uniquely identifies the prompt across all bank files. Scraped ids
     start with ["wiki-"] so they cannot clash with ids in
     [data/bank/handwritten.json]. *)
  id : string;
  (* [text] is the question shown to players. *)
  text : string;
  (* [page] is the Wikipedia page title as it appears in the URL, with
     underscores instead of spaces, e.g. ["List_of_chemical_elements"]. *)
  page : string;
  (* [extractor] says how to find the answers on [page]. *)
  extractor : extractor;
}
(** [source] is one prompt the scraper produces, and where its answers come
    from. *)

(** [sources] is every prompt the scraper builds, in output order. Requires: all
    [id]s are distinct. *)
let sources : source list =
  [
    {
      id = "wiki-elements";
      text = "Name a chemical element";
      page = "List_of_chemical_elements";
      extractor = Table { index = 0; column = 2 };
    };
    {
      id = "wiki-africa";
      text = "Name a country in Africa";
      page = "List_of_sovereign_states_and_dependent_territories_in_Africa";
      extractor = Table { index = 0; column = 2 };
    };
    {
      id = "wiki-europe";
      text = "Name a country in Europe";
      page = "List_of_sovereign_states_and_dependent_territories_in_Europe";
      extractor = Table { index = 0; column = 2 };
    };
    {
      id = "wiki-beatles";
      text = "Name a song recorded by the Beatles";
      page = "List_of_songs_recorded_by_the_Beatles";
      extractor = Table { index = 1; column = 0 };
    };
  ]
