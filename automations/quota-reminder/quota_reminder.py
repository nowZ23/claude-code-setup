#!/usr/bin/env python3
"""Rappel conditionnel : ne notifie que si l'objectif du jour n'est pas atteint.

Lit un journal JSON d'actions : {"log": [{"kind": "...", "ts": "AAAA-MM-JJTHH:MM"}, ...]}
Notifie seulement si l'objectif du jour n'est pas atteint ET que le plafond glissant
sur 7 jours laisse encore de la marge. Sinon : silencieux.

Réglages par variables d'environnement :
  QUOTA_LOG     chemin du journal JSON        (défaut ~/.quota/actions.json)
  QUOTA_KIND    type d'action compté          (défaut task_done)
  QUOTA_DAILY   objectif quotidien            (défaut 5)
  QUOTA_WEEKLY  plafond sur 7 jours glissants (défaut 25)
  QUOTA_LABEL   titre de la notification      (défaut Objectif du jour)
Lancé par launchd, voir ../launchd/install_agent.py.
"""
import datetime
import json
import os
import pathlib
import subprocess

LOG_FILE = pathlib.Path(os.environ.get("QUOTA_LOG", pathlib.Path.home() / ".quota" / "actions.json"))
KIND = os.environ.get("QUOTA_KIND", "task_done")
DAILY_TARGET = int(os.environ.get("QUOTA_DAILY", 5))
WEEKLY_CAP = int(os.environ.get("QUOTA_WEEKLY", 25))
LABEL = os.environ.get("QUOTA_LABEL", "Objectif du jour")


def counts():
    log = json.loads(LOG_FILE.read_text())["log"]
    today = datetime.date.today()
    week_start = today - datetime.timedelta(days=6)
    hits = [a for a in log if a.get("kind") == KIND]
    day = sum(1 for a in hits if a.get("ts", "")[:10] == today.isoformat())
    week = sum(1 for a in hits if week_start.isoformat() <= a.get("ts", "")[:10] <= today.isoformat())
    return day, week


def notify(title, msg):
    subprocess.run(["osascript", "-e",
                    f'display notification "{msg}" with title "{title}" sound name "Glass"'])


def main():
    try:
        day, week = counts()
    except Exception:
        return  # pas de journal ou fichier illisible : silencieux
    if day >= DAILY_TARGET or week >= WEEKLY_CAP:
        return  # objectif atteint ou plafond touché : on ne harcèle pas
    reste = min(DAILY_TARGET - day, WEEKLY_CAP - week)
    notify(LABEL, f"{day}/{DAILY_TARGET} aujourd'hui. Il reste {reste} à faire.")


if __name__ == "__main__":
    main()
