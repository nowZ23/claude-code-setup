# Automatisations planifiées

Des scripts qui tournent tout seuls sur ton Mac, à heure fixe, via **launchd** (le planificateur de macOS). Ils sont tous génériques : rien n'est codé en dur, chaque chemin, identifiant ou seuil se règle par variable d'environnement ou par un fichier de config.

| Dossier | Ce qu'il fait | Modèle de base |
|---|---|---|
| `isolated-chrome/` | Lance un Chrome dédié, avec son propre profil, pour l'automatisation navigateur | Lanceur idempotent |
| `weekly-sync/` | Synchronise une source externe chaque semaine, puis fait mettre les notes à jour par Claude | Synchro + notes |
| `repo-snapshot/` | Écrit chaque nuit une fiche git (branche, derniers commits, changements) par repo, lecture seule | Snapshot git |
| `quota-reminder/` | Rappelle un objectif quotidien seulement s'il n'est pas atteint | Rappel conditionnel |
| `price-watch/` | Surveille des prix publics et alerte quand l'un passe sous son seuil | Veille de prix |
| `launchd/` | Installe n'importe lequel de ces scripts comme tâche planifiée | Installeur |

## Installation type

1. Copie le dossier voulu dans `~/.claude/` (par exemple `~/.claude/quota-reminder/`).
2. Lis l'en-tête du script : il liste les variables et fichiers à régler.
3. Crée la config (`config.example.json`, `repos.txt.example`, `actions.json.example` servent de modèles).
4. Teste à la main d'abord, puis planifie :
   ```bash
   python3 ~/.claude/launchd/install_agent.py com.moi.quota-reminder 19:00 /usr/bin/python3 ~/.claude/quota-reminder/quota_reminder.py
   ```
5. Pour désinstaller : `launchctl bootout gui/$(id -u)/com.moi.quota-reminder`, puis supprime le `.plist` dans `~/Library/LaunchAgents/`.

## Principes communs

- **Silencieux par défaut** : une notification seulement quand il y a quelque chose à savoir ou à faire.
- **Retry naturel** : si une étape échoue (session expirée, navigateur fermé), le script ne marque pas la tâche comme faite et réessaie au prochain passage.
- **Lecture seule quand c'est possible** : un snapshot git ne modifie jamais le repo.
- **Un profil de navigateur séparé** pour tout ce qui touche à un site connecté. Le navigateur perso reste intouchable.
- **Logs bornés** : chaque script ne garde que les dix ou quatorze derniers journaux.

## Ce qui n'est pas inclus

- Les **moteurs d'action** (envoi de messages, prise de contact, saisie automatique de formulaires) : ils dépendent de ton propre outillage et des règles des plateformes concernées. Le modèle `quota-reminder/` te donne seulement le rappel qui va avec.
- Les **scripts d'extraction** propres à une source (par exemple l'export d'un espace de cours ou d'un CRM) : ils sont spécifiques à chaque source. `weekly-sync/` attend simplement un script qui écrit un `last-report.json` au bon format.
