---
description: "Charge le contexte d'un projet actif depuis le vault Obsidian et fait un point d'état, prêt à continuer le travail."
---

Reprends le travail sur le projet donné en `$ARGUMENTS` (nom du projet) ; si vide, demande en une ligne « quel projet ? ».

**Chemin du vault** : lis-le dans `~/.claude/obsidian-vault.path` et utilise-le pour tous les chemins ci-dessous. Si ce fichier n'existe pas, demande le chemin du vault à l'utilisateur avant d'écrire quoi que ce soit (voir README). Cette commande peut être lancée depuis n'importe quel projet.

## 1. Charge le contexte
Cherche et lis la note projet correspondante (ex. `work/active/<Nom du projet>.md` ou `Projects/<Nom du projet>.md`).
Si elle référence d'autres notes (wikilinks), lis celles qui sont pertinentes pour la suite.

## 2. Fais un point d'état court
Présente, de façon concise :
- **Où on en est** : statut, rôles impliqués, cible/objectif.
- **Décisions / éléments actés**.
- **En attente** : ce qui bloque ou ce qu'on attend.
- **Prochaine action** : la chose la plus utile à faire maintenant, formulée clairement.

## 3. Sois prêt à continuer
Termine en proposant 1 à 3 directions concrètes pour cette session. Ne lance rien sans accord.

## 4. Tiens la note à jour
Au fil de la session, **enregistre les décisions et avancées** dans la note projet (section `## Journal` avec la date, + sections dédiées si besoin). L'objectif : pouvoir toujours « ressortir tout ce qu'on a fait » via cette note. Préserve le frontmatter existant et garde au moins un wikilink.
