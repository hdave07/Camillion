# Camillion Architecture Guide

Internal guide for the O'Camillion team. Read this before you start a branch. It explains what lives where, who owns it, and how the pieces connect.

> **Status:** scaffolding only. Every `.ml`/`.mli` file holds just a header comment. Owners write the real code on their own branches.

---

## 1. Overview

Camillion is a daily trivia game inspired by Krillion: **the rarest valid answer wins.** The player's camel starts on the sand. Each correct answer adds balloons, and rarer answers add more balloons and lift the camel higher (4 to 100 miles).

**MS2 goal:** one playable round on localhost, all the way through the stack. The browser shows the prompts, the player answers against a 25-second countdown, the server matches the answer and scores it, and the browser shows the tier and miles. Part of the bank comes from real Wikipedia data.

---

## 2. Data flow (MS2)

```
OFFLINE BUILD STEP (runs before the game; never at runtime)
┌──────────────────────┐     ┌───────────────────────────┐     ┌──────────────────┐
│ Wikipedia scraper    │ ──▶ │ Answer bank files         │ ──▶ │ Loader           │
│ scraper/main.ml      │     │ data/bank/scraped.json    │     │ src/bank.ml      │
│ Harini               │     │ data/bank/handwritten.json│     │ Roma · validates │
└──────────────────────┘     │ Roma · format             │     └────────┬─────────┘
                             └───────────────────────────┘              │
RUNTIME (one round on localhost, one answer at a time)                  ▼
┌──────────────────────┐     ┌───────────────────────────┐     ┌──────────────────┐
│ Browser UI           │ ◀─▶ │ Dream server              │ ◀── │ Round engine     │
│ web/main.ml          │     │ server/main.ml            │     │ src/engine.ml    │
│ Meira · countdown    │     │ Teju · 2 endpoints        │     │ Saranya · prompts│
└──────────────────────┘     └─────────────┬─────────────┘     └──────────────────┘
          ▲                                ▼
          │                  ┌───────────────────────────┐     ┌──────────────────┐
          │                  │ Matcher                   │ ──▶ │ Scoring          │
          │                  │ src/normalizer.ml         │     │ src/scoring.ml   │
          │                  │ src/matcher.ml · Teju     │     │ Saranya · miles  │
          │                  └───────────────────────────┘     └────────┬─────────┘
          │                                                             │
          └──────────── Result screen (web/, Meira · tier + miles) ◀────┘

FALLBACK: bin/main.ml calls the same Bank → Engine → Matcher → Scoring directly in the terminal.
```

**One answer, step by step:**
1. At startup, the server reads `data/bank/*.json` and passes the parsed JSON to `Bank`, which validates it and reports malformed entries.
2. The browser calls `GET /api/round`. The server asks `Engine` for the round's prompts (picked by seed) and returns them.
3. The player types an answer. The browser sends the raw text to `POST /api/answer`.
4. The server runs `Normalizer` and then `Matcher` against that prompt's answers and aliases. The match gives a `Tier`.
5. `Scoring` turns the tier into balloons and miles. The server returns `{tier, balloons, miles}`.
6. The browser animates the camel and shows the result screen.

---

## 3. Directory map

| Path | What it is | Owner (primary / secondary) | Allowed dependencies |
|---|---|---|---|
| `dune-project`, `camillion.opam` | Build config. The `.opam` file is **generated** from `dune-project`, so don't edit it by hand | Saranya / Teju | — |
| `Makefile` | Shortcuts: `build test fmt serve play scrape clean` | Saranya / Teju | — |
| `.ocamlformat` | Formatter config (ocamlformat 0.29.0) | Saranya / Teju | — |
| `src/` | Core library `camillion`: all game logic | see module guide | **yojson only.** No Unix, no network, no file IO: this code must also compile to JavaScript |
| `server/` | Dream server: the 2 MS2 endpoints and static files | Teju / Meira | camillion, dream, lwt, yojson |
| `web/` | Browser front end, compiled to JS (`_build/default/web/main.bc.js`) | Meira / Saranya | camillion, brr, js_of_ocaml-lwt, lwt |
| `web/static/` | `index.html` and `style.css`, served by the server | Meira / Saranya | — |
| `bin/` | Terminal fallback version of the game | everyone | camillion, yojson |
| `scraper/` | Offline Wikipedia scraper that writes `data/bank/scraped.json` | Harini / Roma | camillion, lwt, cohttp-lwt-unix, lambdasoup, yojson |
| `data/bank/handwritten.json` | Hand-written starter prompts | Roma / Harini | — |
| `data/bank/scraped.json` | Scraper output: 2–3 real Wikipedia prompts | Harini / Roma | — |
| `data/raw/` | Scraper download cache (gitignored) | Harini | — |
| `test/` | OUnit tests, one `test_<module>.ml` per area | each module's owner | camillion, ounit2 |
| `docs/` | This guide | everyone | — |

**Why there are two bank files:** Harini's scraper and Roma's hand-written prompts never edit the same file, so they can't cause merge conflicts. Both use the same format, and the loader reads every `.json` in `data/bank/`.

---

## 4. Module guide (`src/`)

Inside the library, modules refer to each other directly (`Tier`, `Bank`, …). Code outside `src/` uses `Camillion.Tier`, `Camillion.Bank`, and so on.

| Module | Owner | Responsibility | Used by | Tests |
|---|---|---|---|---|
| `Tier` | shared | The 6 tiers and their miles (see §5) | everyone | `test/test_tier.ml` |
| `Api` | Teju / Meira | Endpoint request and response types and their JSON conversion | server, web | — (covered by the server) |
| `Bank` | Roma / Harini | Bank types; validate the JSON and report malformed entries | server, bin, engine, matcher, scraper | `test/test_bank.ml` |
| `Normalizer` | Teju / Meira | Case, accents, punctuation, plurals | matcher | `test/test_matcher.ml` |
| `Matcher` | Teju / Meira | Normalized input plus aliases plus typo tolerance → matched answer or tier | server, bin | `test/test_matcher.ml` |
| `Engine` | Saranya / Teju | Pick a round's prompts from the bank with a seed; game state; countdown rule | server, bin | `test/test_engine.ml` |
| `Scoring` | Saranya / Teju | Tier → balloons and miles; a timeout adds 0 | server, bin | `test/test_scoring.ml` |

Every `.ml` has a matching `.mli`. **Write the `.mli` first**, with comments on each function, so whoever uses your module knows what to call.

---

## 5. Shared contracts

These are the agreements that let people work in parallel. **Before changing any of them, message the team channel and get agreement** (team contract → "Review and integration").

### 5.1 Tiers (`src/tier.mli`) — fixed by the proposal

| Tier | Miles | Meaning |
|---|---|---|
| Sand | 4 | A common answer given by most |
| Breeze | 8 | Common, but not the first thought |
| Updraft | 16 | Uncommon |
| Jet Stream | 32 | Obscure |
| One in a Camillion | 64 | A super rare answer |
| Interstellar | 100 | THE single rarest answer for the prompt |

A timed-out answer adds 0 miles.

### 5.2 Endpoints (`src/api.mli`) — ⚠️ DRAFT until Thursday (Teju + Meira)

| Route | Request | Response |
|---|---|---|
| `GET /api/round` | (later: seed / date) | `{ "prompts": [ { "id": ..., "text": ... }, ... ] }` |
| `POST /api/answer` | `{ "prompt_id": ..., "text": "<raw player input>" }` | `{ "tier": ..., "balloons": ..., "miles": ... }`, or a "no match" response |

The server also serves `/` (`web/static/index.html`), `/static/**` (`web/static/`), and `/main.js` (`_build/default/web/main.bc.js`).

Once the shape is agreed, Meira can build against a hardcoded response while Teju finishes the server.

### 5.3 Bank file format (`src/bank.mli`)

The bank files currently hold `[]`. Each prompt needs at least: an id, the prompt text, and a list of accepted answers. Each answer has its canonical name, aliases and tier. Once Roma fixes the format, update this section with an example, and Harini's scraper must write exactly that format.

---

## 6. How to

### Setup (once per machine)
```sh
# macOS system libraries needed by Dream
brew install gmp libev pkgconf
# OCaml dependencies listed in dune-project
opam install . --deps-only --with-test
```

### Everyday commands
| Command | What it does |
|---|---|
| `make` / `dune build` | Build everything (library, server, web JS, bin, scraper, tests) |
| `make test` / `dune test` | Run OUnit tests |
| `make fmt` | Auto-format all OCaml and dune files |
| `make serve` | Start the Dream server, then open `http://localhost:8080` |
| `make play` | Terminal fallback game |
| `make scrape` | Run the offline scraper |

Run commands from the **repo root**, because the server and bin read `data/` and `web/static/` using relative paths.

### Adding a module to the core library
1. Create `src/foo.mli` and `src/foo.ml`. No dune change is needed, since dune picks up every module in `src/`.
2. Keep it pure (§3). If it needs files or the network, the IO goes in `server/`, `bin/` or `scraper/` instead.
3. Create `test/test_foo.ml` with `let suite = "foo" >::: [ ... ]` and add it to the runner in `test/main.ml`.

### Adding a dependency
Add it to `depends` in `dune-project` **and** to the `libraries` of the relevant `dune` file, then run `dune build`, which regenerates `camillion.opam`. Tell the team so they can run `opam install . --deps-only`.

---

## 7. Workflow

- `main` always builds. Never commit directly to `main` after the scaffold.
- Branch per task: `<netid>/<topic>`
- Before opening a PR, run `make fmt && dune build && dune test`.
- Open a PR. The **secondary owner** of that area reviews it (team contract).
- After merging, run the full test suite on `main`.
- Changes to anything in §5 need a team-channel message first.
- AI-assisted code must be explainable by its author. Cite substantial AI-generated code in the PR description.

---

## 8. Features coming after MS2 (no files created yet)

The full proposal includes features that aren't part of the MS2 slice. This list says which folder each one goes in once someone builds it, so nobody invents a different place for it.

| Feature | Goes in | Owner |
|---|---|---|
| Rarity blending: player answer counts + Wikipedia page-view prior (~10 imaginary responses), tiers recomputed hourly | new `src/rarity.ml` (pure, tested on synthetic counts) | Roma |
| Page-view → initial tier percentiles | `scraper/` (or `src/rarity.ml` if shared) | Harini / Roma |
| Submission store (how often each answer is given) and the hourly recompute | `server/` | Teju |
| Daily snapshot of tiers, so scoring stays stable for the day | `server/` + `src/engine.ml` | Teju / Saranya |
| Streaks, play history, highest flights | `src/engine.ml` or new `src/history.ml` | Saranya |
| "New challenge" button, recently seen prompts, local storage, share/stats screens | `web/` | Meira |
| Avoid-recent-prompts list passed into the round engine | `src/engine.ml` | Saranya |
