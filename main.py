from http.server import BaseHTTPRequestHandler, HTTPServer
import json
from dataclasses import dataclass
from datetime import datetime
import re

@dataclass
class Ticket:
    id: int
    uhrzeit: str
    name: str
    anfrage: str
    category: str

CATEGORIES = {
    "Drucker": [
        "drucker", "print", "druckt nicht", "papierstau", "toner", "patrone", "scanner", "scan", "warteschlange"
    ],
    "Netzwerk": [
        "wlan", "wifi", "lan", "netzwerk", "internet", "vpn", "dns", "ip", "verbindung", "kein netz"
    ],
    "Microsoft Software": [
        "outlook", "teams", "excel", "word", "powerpoint", "onedrive", "sharepoint", "office", "m365", "microsoft"
    ],
    "Windows Update": [
        "update", "windows update", "neu starten", "neustart", "patch", "aktualisierung"
    ],
    "Login/Account": [
        "passwort", "login", "anmelden", "konto", "account", "gesperrt", "2fa", "mfa", "pin"
    ],
    "Hardware": [
        "tastatur", "maus", "monitor", "bildschirm", "akku", "netzteil", "dock", "headset", "mikrofon", "kamera"
    ],
    "Sonstiges": []
}


def normalize(text) -> str:
    text = text.lower().strip()
    text = re.sub(r"\s+", " ", text)
    return text


def find_Keywords(text, categories):
    found = {}

    for category, keywords in categories.items():
        hits = []

        for keyword in keywords:
            if keyword in text:
                hits.append(keyword)

        if hits:
            found[category] = hits

    #print("gefunden: " + str(found))
    return found


def find_Category(found):

    best_category = ""
    max_hits = 0

    if found:
        for category in found:
            if len(found[category]) > max_hits:
                max_hits = len(found[category])
                best_category = category

        return best_category


def create_ticket(ticket_id, name_anfrage, text):

    text = normalize(text)
    found = find_Keywords(text, CATEGORIES)
    category_found = find_Category(found)

    return Ticket(
        id = ticket_id,
        uhrzeit = datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        name = name_anfrage,
        anfrage = text,
        category = category_found,
    )


"""ticket_id = 1
while True:
    name = input("Name/Abteilung: ").strip()
    if name.lower() == "quit":
        break

    anfrage = input("Bitte Beschreiben sie ihr Problem: ").strip()
    if anfrage.lower() == "quit":
        break

    ticket = create_ticket(ticket_id, name, anfrage)
    print()
    print("Ticket:")
    print(ticket)
    print()

    ticket_id += 1
"""
class TicketHandler(BaseHTTPRequestHandler):
    ticket_id = 1
    tickets = []

    def _set_headers(self, code=200):
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Access-Control-Allow-Headers", "*")
        self.end_headers()
    
    def do_POST(self):
        if self.path != "/chat":
            self._set_headers(404)
            self.wfile.write(json.dumps({"error": "NOT Found"}).encode())
            return
        
        content_length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(content_length)
        try:
            data = json.loads(body)
            username = data.get("username")
            message = data.get("message")
        except Exception:
            self._set_headers(400)
            self.wfile.write(json.dumps({"error": "Invalid JSON"}).encode())
            return
        
        if not username or not message:
            self._set_headers(400)
            self.wfile.write(json.dumps({"error": "Missing username or message"}).encode)
            return
        
        ticket = create_ticket(TicketHandler.ticket_id, username, message)
        TicketHandler.tickets.append(ticket)
        TicketHandler.ticket_id += 1

        response = {
            "ticket_id": ticket.id,
            "timestamp": ticket.uhrzeit,
            "category": ticket.category,
            "message": f"Ticket erstellt für {ticket.name} ({ticket.category})"
        }

        self._set_headers(200)
        self.wfile.write(json.dumps(response).encode())

if __name__ == "__main__":
    server_address = ("", 5000)
    httpd = HTTPServer(server_address, TicketHandler)
    print("Server läuft auf http://localhost:5000/chat")
    httpd.serve_forever()