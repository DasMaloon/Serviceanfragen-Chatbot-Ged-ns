open Raylib

let () =
  init_window 800 600 "ChatBot";
  set_target_fps 16;

  let chatbox = Chatbox.create 50 50 700 500 in
  let username = ref None in
  let api_url = "http://localhost:5000/chat" in

  Chatbox.add_message chatbox "System"
    "Please enter your username.";

  let rec loop () =
    if window_should_close () then close_window ()
    else begin
      Chatbox.update chatbox;

      if is_key_pressed Key.Enter then begin
        let input = Chatbox.get_input chatbox in
        if input <> "" then begin
          match !username with
          | None ->
              username := Some input;
              Chatbox.add_message chatbox "System"
                ("Welcome, " ^ input ^ "!");
              Chatbox.clear_input chatbox

          | Some name ->
              Chatbox.add_message chatbox name input;
              Chatbox.clear_input chatbox;

              let json =
                Api.post_chat api_url
                  ~username:name
                  ~message:input
              in

              begin match Response.of_json json with
              | Response.Answer msg ->
                  Chatbox.add_message chatbox "Assistant" msg

              | Response.Ticket { category } ->
                  Chatbox.add_message chatbox "Ticket-System"
                    ("Ticket created (Category: " ^ category ^ ")")
              end
        end
      end;

      begin_drawing ();
      clear_background Color.raywhite;
      Chatbox.draw chatbox;
      end_drawing ();
      loop ()
    end
  in
  loop ()
