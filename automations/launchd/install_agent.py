#!/usr/bin/env python3
"""Crée et charge une tâche planifiée macOS (agent launchd) pour un script.

Usage :
  python3 install_agent.py <label> <HH:MM[,HH:MM...]> <programme> [arguments...]

Exemple :
  python3 install_agent.py com.moi.quota-reminder 19:00 /usr/bin/python3 ~/.claude/quota-reminder/quota_reminder.py

- Le label doit être unique et commencer par ton identifiant inversé (com.toi.nom).
- Utilise des chemins complets (pas de ~ dans les arguments : launchd ne le développe pas, passe $HOME ou un chemin absolu).
- Les logs vont dans ~/.claude/logs/<label>.out et .err.
- Relancer la commande remplace l'agent existant (idempotent).
- Désinstaller : launchctl bootout gui/$(id -u)/<label> puis supprimer ~/Library/LaunchAgents/<label>.plist
"""
import os
import pathlib
import plistlib
import subprocess
import sys

if len(sys.argv) < 4:
    sys.exit(__doc__)

label, times, *program = sys.argv[1:]
intervals = []
for t in times.split(","):
    hour, minute = t.split(":")
    intervals.append({"Hour": int(hour), "Minute": int(minute)})

logs = pathlib.Path.home() / ".claude" / "logs"
logs.mkdir(parents=True, exist_ok=True)
plist = {
    "Label": label,
    "ProgramArguments": program,
    "StartCalendarInterval": intervals if len(intervals) > 1 else intervals[0],
    "RunAtLoad": False,
    "EnvironmentVariables": {
        "PATH": f"{pathlib.Path.home() / '.local/bin'}:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin",
    },
    "StandardOutPath": str(logs / f"{label}.out"),
    "StandardErrorPath": str(logs / f"{label}.err"),
}

agents = pathlib.Path.home() / "Library" / "LaunchAgents"
agents.mkdir(parents=True, exist_ok=True)
path = agents / f"{label}.plist"
with open(path, "wb") as f:
    plistlib.dump(plist, f)

uid = f"gui/{os.getuid()}"
subprocess.run(["launchctl", "bootout", uid, str(path)], capture_output=True)  # idempotent
subprocess.run(["launchctl", "bootstrap", uid, str(path)], check=True)
print(f"Agent {label} installé : {path}")
