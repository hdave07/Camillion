.PHONY: default build test fmt serve play scrape clean

default: build

build:
	dune build

test:
	dune test

fmt:
	dune build @fmt --auto-promote

# Run the Dream server from the repo root (it serves web/static and the compiled JS).
serve: build
	dune exec server/main.exe

# Terminal fallback version of the game.
play: build
	dune exec bin/main.exe

# Offline scraper: writes data/bank/scraped.json.
scrape: build
	dune exec scraper/main.exe

clean:
	dune clean
