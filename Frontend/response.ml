open Yojson.Basic.Util

type t =
  | Answer of string
  | Ticket of { category : string }

let of_json json =
  match json |> member "type" |> to_string with
  | "answer" ->
      Answer (json |> member "message" |> to_string)

  | "ticket" ->
      Ticket { category = json |> member "category" |> to_string }

  | _ ->
      failwith "Unknown response type"
