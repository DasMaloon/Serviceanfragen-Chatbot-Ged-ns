open Raylib
open Lwt
open Cohttp
open Cohttp_lwt_unix

let make_post_request url username message =
  let json = Printf.sprintf {|{"username": "%s", "message": "%s"}|} username message in
  let headers = Header.init_with "Content-Type" "application/json" in
  let body = Cohttp_lwt.Body.of_string json in
  Lwt_main.run (
    Client.post ~headers ~body (Uri.of_string url) >>= fun (resp, body) ->
    let code = resp |> Response.status |> Code.code_of_status in
    Printf.printf "Response code: %d\n" code;
    body |> Cohttp_lwt.Body.to_string >|= fun response_body ->
    response_body
  )

let () =
  init_window 800 600 "ChatBot";
  set_target_fps 16;

  let chatbox = Chatbox.create 50 50 700 500 in
  let username = ref None in
  let api_url = "http://localhost:5000/chat" in

  Chatbox.add_message chatbox "System" "Pls enter your username so we can take your requests.";

  let rec loop() =
    if window_should_close () then 
      close_window()
  else begin
    Chatbox.update chatbox;

   if is_key_pressed Key.Enter then begin
        let user_input = Chatbox.get_input chatbox in
        
        if user_input <> "" then begin
          match !username with
          | None ->
            
            username := Some user_input;
            Chatbox.add_message chatbox "System" ("Welcome, " ^ user_input ^ "! How can i help you today?");
            Chatbox.clear_input chatbox;

          | Some name -> begin
            
            Chatbox.add_message chatbox name user_input;
            Chatbox.add_message chatbox "System" ("Ok i have created a ticket for you, you will hear from us shortly. Hope this helps");
            Chatbox.clear_input chatbox;
            
            try
              let response = make_post_request api_url name user_input in
              Printf.printf "API Response: %s\n" response;
              Chatbox.add_message chatbox "Ticket-System" response;
            with
            | e -> 
                Printf.printf "Error: %s\n" (Printexc.to_string e);
                Chatbox.add_message chatbox "Ticket-System" "Sorry, there was an error processing your request."
                        
          end;
          
          Chatbox.clear_input chatbox
        
        end
      
      end;

    begin_drawing();
    clear_background Color.raywhite;
    Chatbox.draw chatbox;
    end_drawing();
    loop ()
  end
in
loop()