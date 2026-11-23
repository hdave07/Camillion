(* tier.mli

   Owner: shared (agreed by whole team)

   Shared contract: the six rarity tiers (Sand, Breeze, Updraft, Jet Stream, One
   in a Camillion, Interstellar) and the miles each is worth (4, 8, 16, 32, 64,
   100).

   See docs/ARCHITECTURE.md. *)

type t =
  | Sand
  | Breeze
  | Updraft
  | JetStream
  | OneInACamillion
  | Interstellar
