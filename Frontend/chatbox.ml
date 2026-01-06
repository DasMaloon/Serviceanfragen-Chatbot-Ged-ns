open Raylib 

type message = {
  sender: string;
  text: string;
}

type t = {
  x: int;
  y: int;
  width: int; 
  height: int;
  bg_color: Color.t;
  border_color: Color.t;
  border_thickness: int;
  mutable input_text: string;
  mutable cursor_visable: bool;
  mutable blink_timer: float;
  mutable messages: message list;
  mutable scroll_offset: int;
}

let create x y width height = {
  x;
  y;
  width;
  height;
  bg_color = Color.white;
  border_color = Color.darkgray;
  border_thickness = 2;
  input_text = "";
  cursor_visable = true;
  blink_timer = 0.0;
  messages = [];
  scroll_offset = 0;
}

let update chatbox = 
  let key = get_char_pressed () in
  if Uchar.to_int key > 0 && Uchar.to_int key <> 13 && Uchar.to_int key <> 10 then
    chatbox.input_text <- chatbox.input_text ^ String.make 1 (Char.chr (Uchar.to_int key));

  if is_key_pressed Key.Backspace && String.length chatbox.input_text > 0 then
    chatbox.input_text <- String.sub chatbox.input_text 0 (String.length chatbox.input_text - 1);

  let wheel = get_mouse_wheel_move () in
  if wheel <> 0.0 then begin
    chatbox.scroll_offset <- chatbox.scroll_offset + int_of_float (wheel *. 30.0);
    if chatbox.scroll_offset > 0 then chatbox.scroll_offset <- 0
  end;

  chatbox.blink_timer <- chatbox.blink_timer +. get_frame_time ();
  if chatbox.blink_timer > 0.5 then begin
    chatbox.cursor_visable <- not chatbox.cursor_visable;
    chatbox.blink_timer <- 0.0
  end

let add_message chatbox sender text =
  let msg = { sender; text } in
  chatbox.messages <- chatbox.messages @ [msg];
  (* Auto-scroll to bottom when new message is added *)
  chatbox.scroll_offset <- 0

let wrap_text text max_width font_size =
  let words = String.split_on_char ' ' text in
  let lines = ref [] in
  let current_line = ref "" in
  
  List.iter (fun word ->
    let test_line = 
      if !current_line = "" then word 
      else !current_line ^ " " ^ word 
    in
    let width = measure_text test_line font_size in
    if width > max_width then begin
      if !current_line <> "" then lines := !lines @ [!current_line];
      current_line := word  
    end else
      current_line := test_line
  ) words;
  
  if !current_line <> "" then lines := !lines @ [!current_line];
  !lines
  
let draw chatbox =
  draw_rectangle chatbox.x chatbox.y chatbox.width chatbox.height chatbox.bg_color;
  
  draw_rectangle_lines chatbox.x chatbox.y chatbox.width chatbox.height chatbox.border_color;
  for i = 1 to chatbox.border_thickness -1 do 
    draw_rectangle_lines
      (chatbox.x -i)
      (chatbox.y - i)
      (chatbox.width + 2 * i)
      (chatbox.height + 2 * i)
      chatbox.border_color
  done;

  let message_area_height = chatbox.height - 60 in
  begin_scissor_mode chatbox.x chatbox.y chatbox.width message_area_height;

  let message_y = ref (chatbox.y + 10 + chatbox.scroll_offset) in
  let max_text_width = chatbox.width - 30 in
  
  List.iter (fun msg ->
    let full_text = msg.sender ^ ": \"" ^ msg.text ^ "\"" in
    let wrapped_lines = wrap_text full_text max_text_width 20 in
    
    List.iter (fun line ->
      if !message_y >= chatbox.y - 25 && !message_y < chatbox.y + message_area_height then
        draw_text line (chatbox.x + 10) !message_y 20 Color.darkgray;
      message_y := !message_y + 25
    ) wrapped_lines
  ) chatbox.messages;
  end_scissor_mode ();

  draw_line chatbox.x (chatbox.y + message_area_height) 
            (chatbox.x + chatbox.width) (chatbox.y + message_area_height) 
            Color.lightgray;
  
  let text_y = chatbox.y + chatbox.height - 40 in
  let input_display = 
    if String.length chatbox.input_text * 10 > chatbox.width - 30 then
      String.sub chatbox.input_text 
        (String.length chatbox.input_text - ((chatbox.width - 30) / 10))
        ((chatbox.width - 30) / 10)
    else
      chatbox.input_text
  in
  draw_text input_display (chatbox.x + 10) text_y 20 Color.black;

  if chatbox.cursor_visable then begin
    let text_width = measure_text input_display 20 in
    draw_text "|" (chatbox.x + 10 + text_width) text_y 20 Color.black
  end

  let get_input chatbox = chatbox.input_text

  let clear_input chatbox = 
    chatbox.input_text <- "";

