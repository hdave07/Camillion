(* fetch.ml Downloads a URL over HTTP, with a disk cache in data/raw/. A page is
   downloaded at most once; later runs read the saved copy. Failed downloads are
   never cached. *)

(** [user_agent] identifies this program to Wikipedia. Wikimedia's API policy
    asks every client to send a descriptive User-Agent. *)
let user_agent = "CamillionScraper/0.1 (CS 3110 class project)"

(** [cache_dir] folder where downloaded pages are saved. *)
let cache_dir = "data/raw"

(** [cache_path url] is the file in [cache_dir] where the body of [url] is
    saved. The name is [url] with every character other than letters, digits,
    ['-'] and ['.'] replaced by ['_'] (cut to 100 characters), followed by the
    first 8 hex digits of the MD5 hash of [url]. *)
let cache_path (url : string) : string =
  let safe =
    String.map
      (fun c ->
        match c with
        | 'a' .. 'z' | 'A' .. 'Z' | '0' .. '9' | '-' | '.' -> c
        | _ -> '_')
      url
  in
  let short =
    if String.length safe > 100 then String.sub safe 0 100 else safe
  in
  (*creates MD5 hash from url, changes to 32 hex characters, takes first 8
    characters*)
  let hash = String.sub (Digest.to_hex (Digest.string url)) 0 8 in
  (*concat file name, short link, hash*)
  Filename.concat cache_dir (short ^ "-" ^ hash ^ ".cache")

(** [read_file path] is a promise of the whole contents of the file at [path].
    Raises: [Unix.Unix_error] if the file cannot be opened. *)
let read_file (path : string) : string Lwt.t =
  Lwt_io.with_file ~mode:Lwt_io.Input path Lwt_io.read

(** [write_file path text] is a promise that writes [text] to the file at
    [path], creating it or replacing its old contents. Raises: [Unix.Unix_error]
    if the file cannot be opened *)
let write_file (path : string) (text : string) : unit Lwt.t =
  Lwt_io.with_file ~mode:Lwt_io.Output path (fun channel ->
      Lwt_io.write channel text)

(** [download url] is a promise of [Ok body] if a GET request to [url] answers
    with status 200, and [Error message] otherwise: for any other status (e.g.
    404 or 429), or if the request itself fails (e.g. no internet). Never
    raises. Does not read or write the cache. *)
let download (url : string) : (string, string) result Lwt.t =
  let headers = Cohttp.Header.of_list [ ("User-Agent", user_agent) ] in
  try%lwt
    let%lwt response, body =
      Cohttp_lwt_unix.Client.get ~headers (Uri.of_string url)
    in
    (* Always read the body, even on an error, so the connection is freed. *)
    let%lwt text = Cohttp_lwt.Body.to_string body in
    let code = Cohttp.Code.code_of_status (Cohttp.Response.status response) in
    if code = 200 then Lwt.return (Ok text)
    else Lwt.return (Error (Printf.sprintf "HTTP %d for %s" code url))
  with exn ->
    Lwt.return
      (Error
         (Printf.sprintf "request failed for %s: %s" url
            (Printexc.to_string exn)))

(** [fetch url] is a promise of [Ok body] for [url]. If [url] was downloaded
    before, [body] comes from the cache and no request is made. Otherwise it is
    downloaded, and saved to the cache only if the download succeeded. It is
    [Error message] if the download fails; nothing is cached. Requires:
    [cache_dir] exists from the repo root. *)
let fetch (url : string) : (string, string) result Lwt.t =
  let path = cache_path url in
  let%lwt cached = Lwt_unix.file_exists path in
  if cached then
    let%lwt text = read_file path in
    Lwt.return (Ok text)
  else
    match%lwt download url with
    | Ok text ->
        let%lwt () = write_file path text in
        Lwt.return (Ok text)
    | Error message -> Lwt.return (Error message)
