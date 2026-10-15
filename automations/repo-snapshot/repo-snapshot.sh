#!/bin/zsh
# Snapshot git nocturne : une note par repo dans le vault, plus un index.
# Lecture seule : uniquement des commandes git qui ne modifient ni le repo ni ses fichiers.
# Liste des repos : ~/.claude/repo-snapshot/repos.txt (un chemin par ligne, # = commentaire).
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"

VAULT="$(cat "$HOME/.claude/obsidian-vault.path" 2>/dev/null)"
LIST="$HOME/.claude/repo-snapshot/repos.txt"
OUT="$VAULT/reference"
LOG="$HOME/.claude/logs/repo-snapshot.log"
NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ)
[[ -n "$VAULT" && -f "$LIST" ]] || { echo "$(date '+%F %T')  config manquante" >> "$LOG"; exit 1; }
mkdir -p "$OUT" "$(dirname "$LOG")"

INDEX="$OUT/_Repos Snapshot.md"
{
  echo "---"; echo "title: Repos Snapshot"; echo "last_synced: $NOW"; echo "tags: [reference, index]"; echo "---"; echo
  echo "| Projet | Branche | Dernier commit | Non commités |"; echo "|---|---|---|---|"
} > "$INDEX"

grep -v '^[[:space:]]*#' "$LIST" | grep -v '^[[:space:]]*$' | while read -r repo; do
  repo="${repo/#\~/$HOME}"
  if [[ ! -d "$repo/.git" ]]; then echo "$(date '+%F %T')  ignoré (pas un repo git) : $repo" >> "$LOG"; continue; fi
  name=$(basename "$repo")
  branch=$(git -C "$repo" branch --show-current)
  dirty=$(git -C "$repo" status --porcelain | wc -l | tr -d ' ')
  last=$(git -C "$repo" log -1 --format='%h %s (%cr)' 2>/dev/null)
  remote=$(git -C "$repo" remote -v | head -1 | awk '{print $2}')
  desc=$(head -1 "$repo/README.md" 2>/dev/null | sed 's/^# *//; s/"/'\''/g')
  [[ -z "$desc" ]] && desc="Snapshot git nocturne du repo $name."
  {
    echo "---"; echo "title: $name"; echo "path: $repo"; echo "last_synced: $NOW"
    echo "branch: $branch"; echo "uncommitted_count: $dirty"; echo "tags: [reference, repo-snapshot]"
    echo "description: \"$desc\""; echo "---"; echo
    echo "## Status"; echo "- Branche : $branch · Non commités : $dirty · Remote : ${remote:-aucun}"; echo
    echo "## Recent Commits"; git -C "$repo" log -5 --format='- %h · %s · %cr' 2>/dev/null; echo
    echo "## Working Changes"
    if (( dirty )); then git -C "$repo" status --porcelain | head -10 | sed 's/^/- /'; else echo "clean"; fi; echo
    echo "## Related"; echo "- [[Index]]"
  } > "$OUT/$name.md"
  echo "| [[$name]] | $branch | ${last:-aucun commit} | $dirty |" >> "$INDEX"
done

echo "$(date '+%F %T')  snapshot écrit dans $OUT" >> "$LOG"
