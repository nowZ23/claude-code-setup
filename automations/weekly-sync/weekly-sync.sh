#!/bin/zsh
# Synchro hebdomadaire : une source externe (espace de cours, portail, CRM...) -> notes Claude à jour.
# Lancé chaque soir par launchd, mais ne travaille que si la dernière synchro réussie date d'au moins
# 7 jours (3 le dimanche). Un échec (navigateur fermé, session expirée) est donc retenté le lendemain.
#
# Réglages (variables d'environnement, sinon valeurs par défaut) :
#   VAULT_DIR     vault Obsidian (lu depuis ~/.claude/obsidian-vault.path si absent)
#   SYNC_STATE    dossier où le script de synchro écrit last-report.json (et où last-ok est gardé)
#   SYNC_SCRIPT   script exécuté dans le navigateur isolé, il écrit last-report.json
#   NOTES_PROMPT  prompt confié à Claude quand il y a du nouveau (voir update-prompt.md)
#   CHROME_UP     lanceur du navigateur isolé (voir ../isolated-chrome/)
#   BROWSER_CMD   commande qui exécute un script dans le navigateur (ex. browser-harness)
#
# Format attendu de last-report.json : {"status": "OK...", "date": "AAAA-MM-JJ",
#   "new_files": [...], "updated_files": [...]}   (status = AUTH_REQUIRED si la session a expiré)
export PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"

VAULT_DIR="${VAULT_DIR:-$(cat "$HOME/.claude/obsidian-vault.path" 2>/dev/null)}"
SYNC_STATE="${SYNC_STATE:-$HOME/sync-state/weekly}"
SYNC_SCRIPT="${SYNC_SCRIPT:-$HOME/sync-state/sync.py}"
NOTES_PROMPT="${NOTES_PROMPT:-$HOME/.claude/weekly-sync/update-prompt.md}"
CHROME_UP="${CHROME_UP:-$HOME/.local/bin/isolated-chrome-up.sh}"
BROWSER_CMD="${BROWSER_CMD:-browser-harness}"

LOG_DIR="$HOME/.claude/logs"
LOG="$LOG_DIR/weekly-sync.log"
RUN_LOG="$LOG_DIR/weekly-sync_$(date +%Y-%m-%d_%H-%M-%S).log"
LAST_OK="$SYNC_STATE/last-ok"
REPORT="$SYNC_STATE/last-report.json"
mkdir -p "$LOG_DIR" "$SYNC_STATE"

notify() { osascript -e "display notification \"$2\" with title \"Synchro hebdo\" subtitle \"$1\"" >/dev/null 2>&1; }

# 1. Faut-il tourner aujourd'hui ?
if [[ -f "$LAST_OK" && "$1" != "--force" ]]; then
  days=$(( ( $(date +%s) - $(date -j -f %Y-%m-%d "$(cat "$LAST_OK")" +%s) ) / 86400 ))
  dow=$(date +%u)   # 7 = dimanche
  if (( days < 7 )) && ! (( dow == 7 && days >= 3 )); then
    echo "$(date '+%F %T')  skip (dernière synchro il y a ${days} j)" >> "$LOG"; exit 0
  fi
fi

# 2. Synchro dans le navigateur isolé
{
  echo "== $(date '+%F %T') synchro"
  "$CHROME_UP" || { notify "Navigateur isolé indisponible" "Synchro reportée à demain."; exit 1; }
  "$BROWSER_CMD" < "$SYNC_SCRIPT"
} > "$RUN_LOG" 2>&1

# 3. Lecture du rapport
field() { python3 -c "import json,sys;print(json.load(open(sys.argv[1]))[sys.argv[2]])" "$REPORT" "$1" 2>/dev/null; }
STATUS=$(field status)
[[ "$(field date)" != "$(date +%F)" ]] && STATUS="ERROR"   # rapport périmé = échec

if [[ "$STATUS" == "AUTH_REQUIRED" ]]; then
  notify "Connexion expirée" "Reconnecte-toi dans le navigateur isolé, nouvelle tentative demain soir."
  echo "$(date '+%F %T')  AUTH_REQUIRED  log=$RUN_LOG" >> "$LOG"; exit 0
fi
if [[ "$STATUS" != OK* ]]; then
  notify "Synchro en échec" "Détail dans $RUN_LOG"
  echo "$(date '+%F %T')  ERROR ($STATUS)  log=$RUN_LOG" >> "$LOG"; exit 1
fi

# 4. S'il y a du nouveau, Claude met les notes à jour
CHANGES=$(python3 -c "import json;r=json.load(open('$REPORT'));print(len(r['new_files'])+len(r['updated_files']))")
if (( CHANGES > 0 )) && [[ -n "$VAULT_DIR" ]]; then
  echo "== $(date '+%F %T') mise à jour des notes ($CHANGES changements)" >> "$RUN_LOG"
  (cd "$VAULT_DIR" && claude -p "$(cat "$NOTES_PROMPT")" \
      --permission-mode bypassPermissions --output-format text) >> "$RUN_LOG" 2>&1
fi

date +%F > "$LAST_OK"
SUMMARY="$CHANGES changement(s)"
notify "Synchro hebdo faite" "$SUMMARY"
echo "$(date '+%F %T')  OK  $SUMMARY  log=$RUN_LOG" >> "$LOG"

ls -1t "$LOG_DIR"/weekly-sync_*.log 2>/dev/null | tail -n +11 | xargs rm -f 2>/dev/null
exit 0
