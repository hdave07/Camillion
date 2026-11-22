(* normalizer.mli

   Owner: Teju (primary), Meira (secondary)

   Normalizes raw player input: case, accents, punctuation, plurals.

   This normalizer is used on both the player's input and the answers in the
   same form. *)

val normalize : string -> string
(** [normalize s] returns a standard form of [s] according to the following
    guidelines:
    - ASCII letters are lowercased.
    - Common accented letters (UTF-8, e.g. "é", "Ñ", "ü") become their plain
      ASCII letter; other non-ASCII characters are dropped.
    - Apostrophes and periods are removed (ex. "O'Neill" -> "oneill", "U.S.A."
      -> "usa"); ["&"] becomes ["and"]; every other non-letter, non-digit
      character becomes a space.
    - Multiple consecutive spaces collapse to one, with no leading or trailing
      space.
    - A leading "the", "a" or "an" is dropped if more words follow.
    - The last word is made singular by [singularize].

    Returns [""] for input with no letters or digits. *)

val singularize : string -> string
(** [singularize w] strips a simple English plural ending from one lowercase
    word: "ies" -> "y" ("berries" -> "berry"); "es" after ch, sh, x, z or ss
    ("boxes" -> "box"); otherwise a final "s". Words of 3 letters or fewer, and
    words ending in "ss", "us" or "is" ("glass", "cactus", "paris"), are left
    unchanged. *)
