open Raylib

type message = {
  sender : string;
  text : string;
}

type t = {
  x : int;
  y : int;
  width : int;
  height : int;
  mutable input_text : string;
  mutable messages : message list;
  mutable scroll_offset : int;
}

let create x y width height =
  {
    x; y; width; height;
    input_text = "";
    messages = [];
    scroll_offset = 0;
  }

let update chatbox =
  let key = get_char_pressed () in
  if Uchar.to_int key > 31 then
    chatbox.input_text <-
      chatbox.input_text ^
      String.make 1 (Char.chr (Uchar.to_int key));

  if is_key_pressed Key.Backspace &&
     String.length chatbox.input_text > 0 then
    chatbox.input_text <-
      String.sub chatbox.input_text 0
        (String.length chatbox.input_text - 1)

let add_message chatbox sender text =
  chatbox.messages <- chatbox.messages @ [{ sender; text }];
  chatbox.scroll_offset <- 0

let draw chatbox =
  draw_rectangle chatbox.x chatbox.y
    chatbox.width chatbox.height Color.white;

  let y = ref (chatbox.y + 10) in
  List.iter (fun msg ->
    let line = msg.sender ^ ": " ^ msg.text in
    draw_text line (chatbox.x + 10) !y 20 Color.darkgray;
    y := !y + 25
  ) chatbox.messages;

  draw_text chatbox.input_text
    (chatbox.x + 10)
    (chatbox.y + chatbox.height - 30)
    20 Color.black

let get_input chatbox = chatbox.input_text
let clear_input chatbox = chatbox.input_text <- ""
