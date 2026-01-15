open Lwt
open Cohttp
open Cohttp_lwt_unix
open Yojson.Basic

let post_chat url ~username ~message =
  let body =
    Printf.sprintf {|{"username":"%s","message":"%s"}|}
      username message
  in
  let headers = Header.init_with "Content-Type" "application/json" in

  Lwt_main.run (
    Client.post ~headers ~body:(Cohttp_lwt.Body.of_string body)
      (Uri.of_string url)
    >>= fun (_, body) ->
    body |> Cohttp_lwt.Body.to_string
    >|= Yojson.Basic.from_string
  )
