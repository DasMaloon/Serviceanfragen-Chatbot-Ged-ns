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

    print("gefunden: " + str(found))
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


ticket_id = 1
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