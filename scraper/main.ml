(* main.ml

   Owner: Harini (primary), Roma (secondary)

   Offline scraper: fetches Wikipedia list pages and page-view counts (concurrently with Lwt), caches raw downloads in data/raw/, dedupes, collects aliases, and writes 2-3 real prompts to data/bank/scraped.json in the Bank format.

   See docs/ARCHITECTURE.md. No implementation yet. *)
