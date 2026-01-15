from http.server import BaseHTTPRequestHandler, HTTPServer
import json
from dataclasses import dataclass
from datetime import datetime
import re
import urllib.request


OLLAMA_URL = "http://localhost:11434/api/generate"
OLLAMA_MODEL = "llama3"


@dataclass
class Ticket:
    id: int
    uhrzeit: str
    name: str
    anfrage: str
    category: str

CATEGORIES = [
    "Drucker",
    "Netzwerk",
    "Microsoft Software",
    "Windows Update",
    "Login/Account",
    "Hardware",
    "Sonstiges",
]


def ask_ollama(message: str):
    prompt = f"""
You are an IT helpdesk assistant.

Decide if the user's request is easy to answer.

Easy = common IT questions with a clear solution.
Hard = requires investigation or human action.

If easy:
Respond ONLY with JSON:
{{ "type": "answer", "message": "..." }}

If hard:
Choose ONE category from:
{", ".join(CATEGORIES)}

Respond ONLY with JSON:
{{ "type": "ticket", "category": "..." }}

User message:
"{message}"
"""

    payload = json.dumps({
        "model": OLLAMA_MODEL,
        "prompt": prompt,
        "stream": False
    }).encode()

    req = urllib.request.Request(
        OLLAMA_URL,
        data=payload,
        headers={"Content-Type": "application/json"}
    )

    with urllib.request.urlopen(req, timeout=30) as resp:
        result = json.loads(resp.read())

    return json.loads(result["response"])


def normalize(text: str) -> str:
    text = text.lower().strip()
    return re.sub(r"\s+", " ", text)

def create_ticket(ticket_id, name, text, category):
    return Ticket(
        id=ticket_id,
        uhrzeit=datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        name=name,
        anfrage=normalize(text),
        category=category
    )


class TicketHandler(BaseHTTPRequestHandler):
    ticket_id = 1
    tickets = []

    def _set_headers(self, code=200):
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()

    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.end_headers()

    def do_POST(self):
        if self.path != "/chat":
            self._set_headers(404)
            self.wfile.write(json.dumps({"error": "Not found"}).encode())
            return

        length = int(self.headers.get("Content-Length", 0))
        data = json.loads(self.rfile.read(length))

        username = data.get("username")
        message = data.get("message")

        if not username or not message:
            self._set_headers(400)
            self.wfile.write(json.dumps({"error": "Missing data"}).encode())
            return

        try:
            ai = ask_ollama(message)
        except Exception:
            ai = {"type": "ticket", "category": "Sonstiges"}

        if ai.get("type") == "answer":
            self._set_headers(200)
            self.wfile.write(json.dumps({
                "type": "answer",
                "message": ai.get("message", "Sorry, I couldn't answer that.")
            }).encode())
            return

        category = ai.get("category", "Sonstiges")
        ticket = create_ticket(
            TicketHandler.ticket_id,
            username,
            message,
            category
        )

        TicketHandler.tickets.append(ticket)
        TicketHandler.ticket_id += 1

        self._set_headers(200)
        self.wfile.write(json.dumps({
            "type": "ticket",
            "id": ticket.id,
            "category": ticket.category,
            "message": "Ticket created and forwarded to IT support."
        }).encode())


if __name__ == "__main__":
    server = HTTPServer(("", 5000), TicketHandler)
    print("Server running on http://localhost:5000/chat")
    server.serve_forever()
