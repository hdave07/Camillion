(lang dune 3.0)

(name camillion)

(generate_opam_files true)

(source
 (github hdave07/Camillion))

(authors
 "Meira Chenicheri (mc3227)"
 "Harini Dave (hsd43)"
 "Saranya Pammi (sp2654)"
 "Roma Rangaswamy (rr829)"
 "Teju Vijay (tv95)")

(maintainers "Team Project 19 O'Camillion")

(package
 (name camillion)
 (synopsis "Camillion: the rarest valid answer lifts your camel highest")
 (description
  "A Krillion-inspired daily trivia game for CS 3110. Rarer answers add more balloons and lift the camel higher.")
 (depends
  (ocaml (>= 5.0))
  dune
  yojson
  lwt
  dream
  brr
  js_of_ocaml
  js_of_ocaml-lwt
  cohttp-lwt-unix
  lambdasoup
  (ounit2 :with-test)))
