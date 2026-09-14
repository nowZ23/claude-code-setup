# Claude Code, mon setup

Ma configuration personnelle de [Claude Code](https://claude.com/claude-code) : mémoire externe dans Obsidian, hooks, commandes personnalisées et quelques automatisations. Partagée pour que tu puisses reprendre les bouts qui t'intéressent.

Ce n'est pas un plugin clé en main : ce sont des fichiers à copier dans `~/.claude/` et à adapter à ta propre façon de travailler.

## Vue d'ensemble

| Pièce | Rôle |
|---|---|
| Vault Obsidian | Mémoire durable entre sessions (projets, réseau, décisions, leçons) |
| `CLAUDE.md.example` | Règles globales chargées à chaque session, quel que soit le projet |
| Hooks (`scripts/`) | Injectent le contexte du vault au démarrage, vérifient le style, déclenchent une rétro en fin de session |
| Commandes (`commands/`) | Slash commands réutilisables (`/kickoff`, `/session-retro`, `/brief`, `/relances`, `/resume-project`) |
| Plugins | Marketplaces Obsidian et Notion pour Claude Code |
| Statusline | Barre de statut avec usage/contexte en un coup d'œil |
| Navigateur isolé | Règle pour ne jamais mélanger l'automatisation browser avec ton Chrome perso |

## 1. Obsidian comme cerveau externe

Le principe : Claude Code n'a pas de mémoire entre les sessions, un [vault Obsidian](https://obsidian.md) sert de mémoire longue durée. Une note par projet actif, une note par contact, un dossier `brain/` pour les décisions, patterns et erreurs déjà vécues.

Installation :
1. Crée un vault Obsidian (dossier local standard).
2. Enregistre son chemin dans `~/.claude/obsidian-vault.path` (juste le chemin, en texte brut). Tous les hooks et commandes de ce repo lisent ce fichier pour rester indépendants de la machine.
3. Structure de départ suggérée :
   ```
   vault/
     brain/          # décisions, patterns, pièges, self-critique
       retros/        # rétrospectives de session (auto-générées)
     work/active/     # notes projet en cours
     org/people/      # fiches contact
   ```
4. Installe le plugin Claude Code pour Obsidian, marketplace `kepano/obsidian-skills` (skill `obsidian-markdown`, `obsidian-cli`, etc.), voir la section Plugins ci-dessous.

## 2. `CLAUDE.md` global

`~/.claude/CLAUDE.md` est lu à chaque session, peu importe le dossier de travail. C'est là que vivent les règles permanentes : comment et quand écrire dans le vault, les réflexes de sécurité avant une action irréversible, quand suggérer un `/clear`.

Copie `CLAUDE.md.example` vers `~/.claude/CLAUDE.md` et adapte-le. Le fichier est volontairement court : tout ce qui est trop spécifique va dans le vault (`brain/Self-Critique.md`), pas ici, sinon il est refacturé intégralement à chaque message.

## 3. Hooks

Trois hooks, déclarés dans `settings.json`, à copier dans `~/.claude/scripts/` (`chmod +x`) :

- **`inject-critique.sh`** (`SessionStart`) : au démarrage de chaque session, imprime un résumé de la structure du vault, extrait en direct tes règles de style si tu en as et injecte les leçons condensées de `brain/Self-Critique.md`. Le but : ne jamais reperdre le contexte accumulé, sans pour autant recharger des fichiers entiers à chaque fois.
- **`session-retro-stop.mjs`** (`Stop`) : détecte la fin d'une session substantielle (assez de tours, un signal de clôture du type « c'est bon, merci ») et déclenche une rétrospective honnête, écrite dans `brain/retros/`. Calcule des métriques objectives depuis le transcript (durée, tours, appels d'outils, signaux de friction) plutôt que de laisser le modèle s'auto-évaluer à l'aveugle.
- **`fr-style-guard.mjs`** (`Stop` + `PostToolUse`) : contrôle de style sur les livrables rédactionnels (mails, posts, DM) écrits en français, avant de te les montrer. Les règles codées dedans (tiret cadratin, virgule avant « et »/« ou », etc.) sont un exemple de préférences personnelles, remplace-les par les tiennes.

Ces trois scripts lisent `~/.claude/obsidian-vault.path`, donc portables d'une machine à l'autre sans rien coder en dur.

## 4. Commandes personnalisées

À copier dans `~/.claude/commands/` :

- **`/kickoff <projet>`** : cadre un nouveau projet avant de coder (scope in/out, arborescence, README squelette, checklist de déploiement) et crée la note projet dans le vault.
- **`/session-retro`** : génère la rétrospective (peut aussi être lancée manuellement, pas seulement via le hook Stop).
- **`/brief <sujet>`** : avant tout visuel (post, artifact, landing), produit un brief créatif court plutôt que de foncer sur l'écran blanc.
- **`/relances`** : scanne Gmail (lecture seule) pour les fils qui attendent une réponse et les priorise. Nécessite le MCP Gmail.
- **`/resume-project <nom>`** : recharge le contexte d'un projet actif depuis le vault et fait un point d'état, prêt à continuer.

## 5. Plugins et marketplaces

Ajoutés via `/plugin marketplace add` dans Claude Code :

```
/plugin marketplace add kepano/obsidian-skills
/plugin marketplace add makenotion/claude-code-notion-plugin
```

Puis active les plugins voulus (`obsidian`, `notion-workspace-plugin`). Le `settings.json` fourni ici montre la déclaration correspondante.

## 6. Statusline

La statusline (barre en bas de l'écran, modèle actif, contexte, usage) est un script bash externe, pas quelque chose que j'ai écrit moi-même. Des projets communautaires bien faits existent, par exemple [briansmith80/claude-code-status-bar](https://github.com/briansmith80/claude-code-status-bar). Installe celui qui te convient et déclare-le dans `settings.json` :

```json
"statusLine": {
  "type": "command",
  "command": "bash /Users/YOUR_USER/.claude/statusline-command.sh"
}
```

## 7. Navigateur isolé pour l'automatisation

Pour tout ce qui touche à l'automatisation de navigateur (Claude qui clique, remplit des formulaires, navigue), ne jamais utiliser ton Chrome personnel ni un profil qui a fini par accumuler tes vrais logins. Lance une instance Chrome dédiée avec un profil neuf (`--user-data-dir` sous un dossier temporaire, `--remote-debugging-port` libre) et détruis-la après usage. Si une tâche demande un compte connecté, ouvre la page de login dans cette instance isolée et laisse l'humain taper ses identifiants lui-même.

Pour le contrôle du navigateur via CDP, j'utilise [browser-use/browser-harness](https://github.com/browser-use/browser-harness) (projet tiers, pas inclus ici). La règle d'isolation ci-dessus s'applique à n'importe quel outil de ce type.

## Installation rapide

```bash
git clone https://github.com/nowZ23/claude-code-setup.git
cd claude-code-setup

mkdir -p ~/.claude/scripts ~/.claude/commands
cp scripts/*.sh scripts/*.mjs ~/.claude/scripts/
chmod +x ~/.claude/scripts/*.sh ~/.claude/scripts/*.mjs
cp commands/*.md ~/.claude/commands/

cp CLAUDE.md.example ~/.claude/CLAUDE.md   # puis édite-le

echo "/chemin/vers/ton/vault" > ~/.claude/obsidian-vault.path

# fusionne settings.json avec ton ~/.claude/settings.json existant
# (remplace /Users/YOUR_USER/ par ton propre chemin dans les commandes de hooks)
```

Redémarre Claude Code pour que les hooks et commandes soient pris en compte.

## Licence

MIT, voir `LICENSE`. Fais-en ce que tu veux.
