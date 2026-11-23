# 🐪 O' Camillion 🐪

Authors:
- Meira Chenicheri (mc3227)
- Roma Rangaswamy (rr829)
- Saranya Pammi (sp2654)
- Teju Vijay (tv95)
- Harini Dave (hsd43)

Camillion is a daily trivia game inspired by [Krillion](https://krillion.io/) in which the rarest valid answer to a prompt wins. Players type an answer to each prompt within 25 seconds. Each answer's rarity tier adds balloons that lift the player's camel to a higher altitude. 

## Setup (once per machine)

Requires OCaml 5.0 and opam.

```sh
brew install gmp libev pkgconf            # macOS system libraries for Dream
eval $(opam env)
opam install . --deps-only --with-test    # OCaml dependencies
```

## Build and test

Run every command from the repo root.

```sh
make          # build everything (dune build)
make test     # run all OUnit tests (dune test)
```

## Play in the browser

```sh
make serve
```

Then open **http://localhost:8080**. Upon opening, you will see a start screen, then a round of 3 prompts with a 25-second countdown. You can stop the server with `Ctrl+C`.

## To test the server directly

With `make serve` running, in a second terminal:

```sh
curl localhost:8080/api/round
curl -X POST -d '{"prompt_id":"cornell","text":"the clock tower"}' localhost:8080/api/answer   # match: McGraw Tower
curl -X POST -d '{"prompt_id":"disney","text":"zootropolis"}' localhost:8080/api/answer      # match: Zootopia (alternate name)
curl -X POST -d '{"prompt_id":"fruit","text":"Strawbery"}' localhost:8080/api/answer         # match: Strawberry (typo)
curl -X POST -d '{"prompt_id":"cornell","text":"Ocaml Building"}' localhost:8080/api/answer     # no_match
```

## To rebuild the question bank from Wikipedia (optional)

```sh
make scrape
```

This downloads the Wikipedia list pages in `scraper/config.ml` (cached in
`data/raw/` after the first run) and rewrites `data/bank/scraped.json`.

## Current status (MS2)

- The server plays three temporary demo prompts (fruit, Cornell buildings,
  Disney movies) from `server/demo_round.ml`. It doesn't yet load
  `data/bank/*.json` or use the round engine to pick prompts.
- Balloon counts are placeholders until they're added to the scoring module.
- `make play` (the terminal version in `bin/`) is not implemented yet.

The **[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)** file contains our the project layout,
team member responsibilities, and the team workflow.
