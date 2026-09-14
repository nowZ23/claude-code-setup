#!/bin/zsh
# SessionStart hook (global) : à CHAQUE session Claude Code, oriente vers le
# "cerveau externe" (vault Obsidian) et injecte les règles durables, pour ne
# jamais repartir de zéro ni répéter les erreurs passées — même quand la
# session démarre hors du dossier du vault.
VAULT=$(cat ~/.claude/obsidian-vault.path 2>/dev/null)
VAULT="${VAULT:-$HOME/Documents/Claude/obsidian-mind}"

# --- 0. Orientation : où est le cerveau externe -----------------------------
if [ -d "$VAULT" ]; then
  echo "## 🧠 Cerveau externe (vault Obsidian) — À CONSULTER avant de répondre"
  echo ""
  echo "Ta mémoire durable vit dans le vault Obsidian : \`$VAULT\`."
  echo "**Ne réponds jamais \"de mémoire\" sur ces sujets — va d'abord lire le vault :**"
  echo "- **Personnes / réseau** → \`org/people/\` + \`org/Réseau.md\` (qui est qui, historique des échanges)"
  echo "- **Style d'écriture** (mails, posts, DM) → \`brain/Voix & Outreach.md\` — règles ci-dessous"
  echo "- **Projets en cours** → \`work/active/\` et \`work/Index.md\`"
  echo "- **Objectifs / priorités** → \`brain/North Star.md\`"
  echo "- **Décisions / patterns / pièges** → \`brain/Key Decisions.md\`, \`brain/Patterns.md\`, \`brain/Gotchas.md\`"
  echo ""
  echo "Si un nom, un projet, une collab ou une préférence est évoqué et que tu n'es pas sûr : \`grep\` le vault AVANT de parler. Après un échange utile, mets le vault à jour (fiche personne, réseau, brain)."
  echo ""
fi

# --- 1. Règles de style (extraites en direct pour rester synchro) ------------
# Adapte "Voix & Outreach.md" à ton propre fichier de règles de style, ou
# supprime ce bloc si tu n'as pas ce genre de note.
VOIX="$VAULT/brain/Voix & Outreach.md"
if [ -f "$VOIX" ]; then
  echo "## ✍️ Règles de style — APPLIQUER D'OFFICE (mails, posts, DM)"
  echo ""
  # Extrait la section "## Règles de style ..." jusqu'à la prochaine section (## ),
  # en remplaçant un éventuel bloc de code (script de contrôle) par un rappel
  # d'une ligne pour ne pas gonfler le contexte à chaque session.
  awk '
    /^## Règles de style/{p=1;next}
    /^## /{if(p)exit}
    !p{next}
    /```/{
      if(!f){f=1; print "> (script de contrôle omis ici — voir le fichier source pour le détail)"}
      else{f=0}
      next
    }
    f{next}
    {print}
  ' "$VOIX"
  echo ""
fi

# --- 2. Leçons distillées (Self-Critique) ------------------------------------
# On n'injecte QUE la règle en gras de chaque puce (pas l'anecdote datée) —
# le détail/exemples/historique reste dans le fichier, à lire à la demande.
CRIT="$VAULT/brain/Self-Critique.md"
if [ -f "$CRIT" ]; then
  echo "## 🪞 Leçons de sessions passées (Self-Critique — règles condensées, applique-les proactivement)"
  echo "_Détail/exemples dans \`brain/Self-Critique.md\` : lis-le si une règle a besoin de son contexte._"
  awk '
    BEGIN{fm=0}
    /^---$/{fm++; next}
    fm<2{next}
    /^## /{print ""; print; next}
    /^- /{
      if (match($0, /^- \*\*[^*]*\*\*/)) print substr($0, RSTART, RLENGTH);
      else print $0;
      next
    }
  ' "$CRIT"
fi
