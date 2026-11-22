(* normalizer.ml

   Owner: Teju (primary), Meira (secondary)

   Implementation of Normalizer. *)

(* Accented letters in are encoded in UTF-8 as the byte 0xC3 followed by one
   more byte. [fold_c3 b] maps that second byte to plain lowercase ASCII (both
   upper- and lowercase forms). *)
let fold_c3 = function
  | '\x80' .. '\x85' | '\xA0' .. '\xA5' -> "a"
  | '\x86' | '\xA6' -> "ae"
  | '\x87' | '\xA7' -> "c"
  | '\x88' .. '\x8B' | '\xA8' .. '\xAB' -> "e"
  | '\x8C' .. '\x8F' | '\xAC' .. '\xAF' -> "i"
  | '\x91' | '\xB1' -> "n"
  | '\x92' .. '\x96' | '\x98' | '\xB2' .. '\xB6' | '\xB8' -> "o"
  | '\x99' .. '\x9C' | '\xB9' .. '\xBC' -> "u"
  | '\x9D' | '\xBD' | '\xBF' -> "y"
  | '\x9F' -> "ss"
  | _ -> " "

(* Lowercase, fold accents, and map punctuation to spaces, all in one pass. *)
let clean s =
  let buf = Buffer.create (String.length s) in
  let n = String.length s in
  let rec go i =
    if i < n then
      match s.[i] with
      | 'A' .. 'Z' | 'a' .. 'z' | '0' .. '9' ->
          Buffer.add_char buf (Char.lowercase_ascii s.[i]);
          go (i + 1)
      | '\'' | '.' -> go (i + 1)
      | '&' ->
          Buffer.add_string buf " and ";
          go (i + 1)
      | '\xC3' when i + 1 < n ->
          Buffer.add_string buf (fold_c3 s.[i + 1]);
          go (i + 2)
      | '\xE2' when i + 2 < n && s.[i + 1] = '\x80' && s.[i + 2] = '\x99' ->
          (* U+2019, the curly apostrophe phones insert: treat like ' *)
          go (i + 3)
      | c when Char.code c >= 0x80 -> go (i + 1)
      | _ ->
          Buffer.add_char buf ' ';
          go (i + 1)
  in
  go 0;
  Buffer.contents buf

let ends_with ~suffix w =
  let n = String.length w and k = String.length suffix in
  n >= k && String.sub w (n - k) k = suffix

let singularize w =
  let n = String.length w in
  let chop k = String.sub w 0 (n - k) in
  if n <= 3 then w
  else if ends_with ~suffix:"ies" w && n > 4 then chop 3 ^ "y"
  else if
    List.exists
      (fun suffix -> ends_with ~suffix w)
      [ "ches"; "shes"; "xes"; "zes"; "sses" ]
  then chop 2
  else if List.exists (fun suffix -> ends_with ~suffix w) [ "ss"; "us"; "is" ]
  then w
  else if ends_with ~suffix:"s" w then chop 1
  else w

let rec drop_article = function
  | ("the" | "a" | "an") :: (_ :: _ as rest) -> drop_article rest
  | words -> words

let rec map_last f = function
  | [] -> []
  | [ x ] -> [ f x ]
  | x :: rest -> x :: map_last f rest

let normalize s =
  clean s |> String.split_on_char ' '
  |> List.filter (fun w -> w <> "")
  |> drop_article |> map_last singularize |> String.concat " "
