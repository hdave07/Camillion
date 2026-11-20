# 🐪 O' Camillion 🐪
Authors:
- Meira Chenicheri (mc3227)
- Roma Rangaswamy (rr829)
- Saranya Pammi (sp2654)
- Teju Vijay (tv95)
- Harini Dave (hsd43)


## Getting started

```sh
brew install gmp libev pkgconf            # macOS system libs for Dream
opam install . --deps-only --with-test    # OCaml dependencies
make                                      # dune build
make test                                 # dune test
```

See **[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)** for the project layout, who owns what, the shared contracts (tiers, endpoints, bank format), and the team workflow.
