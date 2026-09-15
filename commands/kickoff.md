---
description: "Cadre un nouveau projet AVANT de coder : scope (in/out), arborescence de dossiers, README squelette, checklist de déploiement, et crée la note projet dans le vault."
---

Cadre le projet **avant** de produire quoi que ce soit. Sujet dans `$ARGUMENTS` ; si vide, demande en une ligne « c'est quoi le projet ? » (nom + en une phrase ce que ça fait).

**Chemin du vault :** `~/.claude/obsidian-vault.path`. Si ce fichier n'existe pas, demande le chemin du vault à l'utilisateur avant d'écrire quoi que ce soit (voir README). Lançable depuis n'importe quel projet.

## 1. Comprends en 1 passe
Reformule le projet en une phrase + **qui l'utilise / quel résultat**. Si un flou change la structure (type d'app, plateforme, y a-t-il un back ?), pose **une** question de cadrage groupée, pas plus.

## 2. Produis la structure (concis, adapté au type)
- **Scope** : `In` (ce qu'on fait pour la v1) vs `Out` (explicitement pas maintenant). C'est le livrable le plus utile, sois tranchant.
- **Arborescence de dossiers** : un arbre réaliste pour ce type de projet (pas un template générique).
- **README squelette** : titre, pitch 1 ligne, stack, install/run, structure, TODO.
- **Checklist de déploiement** : les étapes réelles jusqu'à la mise en ligne (build, env/secrets, store/hébergeur, vérifs). Réutilise les pièges déjà connus (`brain/Gotchas.md`) si pertinents.

## 3. Crée la note projet
Écris `work/active/<Nom du projet>.md` (frontmatter : `date`, `description` ~150 car., `tags: [work-note]`, `status: active`, `quarter`). Colle-y scope + arbo + checklist. **Au moins un wikilink** (une note orpheline est un bug) et ajoute la ligne dans `work/Index.md`. Applique les conventions du vault (charge le skill `obsidian-markdown`).

## 4. Prochaine action
Finis par **la première brique à construire** (une ligne). Ne code rien sans accord.

**Garde-fous :** ne fige pas des partis pris esthétiques/d'identité comme s'ils étaient acquis (sépare gains sûrs et choix ouverts) ; préserve tout contenu existant ; lectures ciblées.
