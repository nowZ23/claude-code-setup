#!/usr/bin/env python3
"""Surveille des prix et alerte quand l'un d'eux passe sous son seuil.

Config : config.json (voir config.example.json). Pour chaque article :
  name        nom affiché
  url         adresse d'une réponse JSON publique (API ou fichier)
  price_path  chemin du prix dans cette réponse, séparé par des points (ex. "data.price")
  target      seuil d'alerte (le script retient aussi 8 % sous la médiane des 30 derniers jours)
Alerte : notification macOS et e-mail via Mail.app si "mail_to" est renseigné.
Lancé par launchd (voir ../launchd/). Avec --test : envoie le résumé tout de suite.
Respecte les conditions d'utilisation des sites que tu surveilles et évite les requêtes trop fréquentes.
"""
import json
import statistics
import subprocess
import sys
import urllib.request
from datetime import datetime, date
from pathlib import Path

HERE = Path(__file__).parent
STATE = HERE / "state.json"
CFG = json.loads((HERE / "config.json").read_text())


def fetch_price(item):
    req = urllib.request.Request(item["url"], headers={"User-Agent": "Mozilla/5.0"})
    data = json.load(urllib.request.urlopen(req, timeout=30))
    for key in item["price_path"].split("."):
        data = data[key]
    return float(data)


def notify(title, body):
    subprocess.run(["osascript", "-e",
                    f'display notification {json.dumps(body[:200], ensure_ascii=False)} '
                    f'with title {json.dumps(title, ensure_ascii=False)} sound name "Glass"'])


def send_mail(subject, body, to):
    script = ('on run argv\ntell application "Mail"\n'
              'set m to make new outgoing message with properties {subject:item 1 of argv, content:item 2 of argv, visible:false}\n'
              'tell m to make new to recipient with properties {address:item 3 of argv}\n'
              'send m\nend tell\nend run')
    subprocess.run(["osascript", "-e", script, subject, body, to], timeout=60)


def alert(title, body):
    notify(title, body)
    if CFG.get("mail_to"):
        send_mail(title, body, CFG["mail_to"])


def main(test=False):
    state = json.loads(STATE.read_text()) if STATE.exists() else {"hist": {}, "alerts": {}}
    today = date.today().isoformat()
    rows = []
    for item in CFG["items"]:
        name = item["name"]
        try:
            price = fetch_price(item)
        except Exception as e:
            rows.append(f"{name} : erreur ({e})")
            continue
        h = state["hist"].setdefault(name, {})
        h[today] = price
        vals = [v for _, v in sorted(h.items())[-30:]]
        # seuil : celui de la config et 8 % sous la médiane 30 j quand l'historique est assez long
        target = item["target"] if len(vals) < 7 else min(item["target"], round(statistics.median(vals) * 0.92, 2))
        hit = price <= target
        rows.append(f"{name} : {price} (seuil {target}){' << SOUS LE SEUIL' if hit else ''}")
        last = state["alerts"].get(name)
        if hit and (not last or (datetime.now() - datetime.fromisoformat(last["t"])).days >= 7
                    or price < last["p"] * 0.97):
            state["alerts"][name] = {"t": datetime.now().isoformat(), "p": price}
            alert(f"Seuil atteint : {name}", f"{name} = {price} (seuil {target})")
    STATE.write_text(json.dumps(state))
    if test or (date.today().weekday() == 6 and state.get("digest") != today):
        state["digest"] = today
        STATE.write_text(json.dumps(state))
        alert("Résumé des prix" + (" (TEST)" if test else ""), "\n".join(rows))


if __name__ == "__main__":
    main(test="--test" in sys.argv)
