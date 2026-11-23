(* main.ml

   Owner: Harini (primary), Roma (secondary)

   Offline scraper, run with [make scrape] from the repo root. For each source
   in [Config.sources], fetches the Wikipedia list page (cached in data/raw/),
   extracts its answers with [Parse], and writes all prompts to
   data/bank/scraped.json in the Bank format.

   MS2: every answer gets no aliases and the placeholder tier. Aliases from
   redirects and tiers from page views come in MS3. *)

open Scraper

(** [output_path] is the bank file the scraper writes. *)
let output_path = "data/bank/scraped.json"

(** [placeholder_tier] is the tier every scraped answer gets until tiers are
    computed from page views (MS3). Spelled like the [Tier.t] constructor, as
    the bank loader expects. *)
let placeholder_tier = "Sand"

(** [page_url page] is the URL of the English Wikipedia article [page]. *)
let page_url (page : string) : string = "https://en.wikipedia.org/wiki/" ^ page

(*Build the JSON values*)
(** [answer_json c] is the bank JSON for candidate [c]: its name as the
    canonical answer, no aliases, and [placeholder_tier]. *)
let answer_json (c : Parse.candidate) : Yojson.Basic.t =
  `Assoc
    [
      ("canonical", `String c.name);
      ("aliases", `List []);
      ("tier", `String placeholder_tier);
    ]

(** [prompt_json source answers] is the bank JSON for the prompt described by
    [source], with [answers] as its accepted answers. *)
let prompt_json (source : Config.source) (answers : Parse.candidate list) :
    Yojson.Basic.t =
  `Assoc
    [
      ("id", `String source.id);
      ("text", `String source.text);
      ("answers", `List (List.map answer_json answers));
    ]
    
(** [scrape_source source] is a promise of [Some json], the bank JSON for
    [source], built from its fetched and parsed list page. If the page cannot be
    fetched or parsed, it prints why and is [None], so that one broken source
    does not stop the others. *)
let scrape_source (source : Config.source) : Yojson.Basic.t option Lwt.t =
   (*wait for page*)
  match%lwt Fetch.fetch (page_url source.page) with
  | Error msg ->
      print_endline (source.id ^ ": skipped, " ^ msg);
      Lwt.return None
  | Ok html -> (
      match Parse.extract source.extractor html with
      | Error msg ->
          print_endline (source.id ^ ": skipped, " ^ msg);
          Lwt.return None
      | Ok answers ->
          Printf.printf "%s: %d answers\n" source.id (List.length answers);
          Lwt.return (Some (prompt_json source answers)))

(** [main ()] is a promise that scrapes every source in [Config.sources], one at
    a time, and writes the prompts that succeeded to [output_path]. *)
let main () : unit Lwt.t =
   (*scrapes source on each source one after another --> to be changed*)
  let%lwt results = Lwt_list.map_s scrape_source Config.sources in
  (*Keeps the Some s and Fun.id is the function that returns its output*)
  let prompts = List.filter_map Fun.id results in
  (*turns ocaml list of JSON to one JSON*)
  let json = `List prompts in
  (*turns jSON to readable test, stored in fetch*)
  let%lwt () =
    Fetch.write_file output_path (Yojson.Basic.pretty_to_string json)
  in
  Printf.printf "wrote %d prompts to %s\n" (List.length prompts) output_path;
  Lwt.return ()

let () = Lwt_main.run (main ())
