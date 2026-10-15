#!/bin/zsh
# Démarre une instance Chrome dédiée à l'automatisation (idempotent : ne fait rien si elle tourne déjà).
# Profil séparé : ton Chrome perso n'est jamais touché et aucune session perso n'est partagée.
# Réglages par variables d'environnement : AUTO_CHROME_PORT (9223 par défaut), AUTO_CHROME_PROFILE.
PORT="${AUTO_CHROME_PORT:-9223}"
PROFILE="${AUTO_CHROME_PROFILE:-$HOME/.auto-chrome-profile}"
CHECK="http://127.0.0.1:$PORT/json/version"

if curl -s --max-time 2 "$CHECK" >/dev/null 2>&1; then exit 0; fi

open -na "Google Chrome" --args \
  --remote-debugging-port=$PORT \
  --user-data-dir="$PROFILE" \
  --no-first-run --no-default-browser-check >/dev/null 2>&1

# attend que le port DevTools réponde (environ 10 s max)
for i in {1..20}; do
  curl -s --max-time 2 "$CHECK" >/dev/null 2>&1 && exit 0
  sleep 0.5
done
echo "isolated-chrome-up: Chrome n'a pas répondu sur le port $PORT" >&2
exit 1
