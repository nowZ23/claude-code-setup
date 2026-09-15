---
description: "Rétrospective de la session en cours : feedback sur les prompts, mes réponses, vitesse, qualité, erreurs. Écrit dans le vault et distille les leçons."
---

Génère une **rétrospective honnête de la session en cours** et stocke-la dans le vault.

**Principe de coût (cette commande doit elle-même être bon marché) :** ne lis JAMAIS `_Retros.md` en entier ni tout `Self-Critique.md`, ce sont de gros fichiers relus à chaque rétro. Lis par tranches ciblées (`grep`, `sed`, anchors) et écris court. La friction est la partie précieuse, le reste est bref.

**Chemin du vault :** `~/.claude/obsidian-vault.path`. Si ce fichier n'existe pas, demande le chemin du vault à l'utilisateur avant d'écrire quoi que ce soit (voir README). Lançable depuis n'importe quel projet.

## 0. Gate de trivialité (à évaluer EN PREMIER)
Une session est **triviale** si : peu de tours utilisateur (~≤2), **aucune friction** et rien de durable produit (méta, test, question isolée). Si triviale, **rétro ultra-courte** : frontmatter + 3-4 lignes max (contexte + la seule observation utile), saute les sections 2 en détail, ne déroule pas 6 rubriques sur du vide. Distille quand même en §4 **s'il y a** une vraie leçon. Sinon, session **substantielle** : suis tout ci-dessous.

## 1. Métriques
- **Chemin normal (hook `Stop`) :** les métriques sont **déjà dans le message déclencheur** (durée, tours, réponses, appels d'outils, friction). Utilise-les telles quelles, **ne relis aucun fichier**.
- **Lancement manuel :** lis `~/.claude/.session-retro/<session_id>.metrics.json` **matché sur le session_id courant**, jamais « le plus récent » (des sessions parallèles écrivent dans ce dossier). Si aucun ne matche, **estime depuis la conversation** et dis-le.

## 2. Analyse (honnête, pas flatteuse)
- **Fait** : 2-4 puces, résultat concret.
- **Qualité** : justesse, complétude, sur/sous-ingénierie. 2-3 phrases, où bon / où moyen.
- **Efficacité** : allers-retours, outils mal choisis, re-lectures évitables (nb d'appels = proxy). 2-3 phrases.
- **Tes prompts** : clairs / ambigus ? Ce qui aurait fait gagner du temps. Constructif.
- **⭐ Frictions / erreurs**, la priorité, développe ici. Chaque fois qu'il a fallu corriger, répéter, dire « non/pas ça » : **cause racine + règle pour l'éviter**.
- **Note** : qualité /5, efficacité /5, autonomie /5, une ligne de justification.

## 3. Écris la rétro
`<vault>/brain/retros/AAAA-MM-JJ-hhmm.md`. Frontmatter : `date`, `description` (~150 car.), `tags: [brain, retro]`, `project`, les 3 notes /5. Puis les sections du §2 (concises). Finis par `## Related` : `[[Self-Critique]]` + `[[retros/_Retros|Retros Index]]` (+ lien projet réel si pertinent, vérifie qu'il existe).

## 4. Distille les leçons (boucle d'apprentissage)
Pour chaque friction qui peut **se reproduire** :
- **Dédoublonne sans tout lire** : `grep -n '^##' Self-Critique.md` pour les sections, puis `grep -in "<2-3 mots-clés de la friction>"`. Si une entrée proche existe, **affine / monte en ⭐ / rejoué le <date>**, ne duplique pas. Sinon, ajoute UNE entrée actionnable dans la bonne section.
- Reste **courte** : Self-Critique est injectée à chaque session. Une friction marginale/à coût nul, une ligne ou rien. Ne la pollue pas.

## 5. Index (ligne COURTE, surtout NE lis pas les grosses lignes existantes)
Écris **une ligne d'une phrase** et insère-la juste **après** le séparateur `|---|---|---|`. Fais-le par **splice scripté** (les vieilles lignes n'entrent jamais dans le contexte) plutôt que Read+Edit. Écris d'abord la ligne dans un fichier temporaire du scratchpad, puis :
```bash
awk 'NR==FNR{r=r $0 ORS; next} {print} /^\|---\|/ && !done{printf "%s", r; done=1}' <scratchpad>/row.txt "$VAULT/brain/retros/_Retros.md" > /tmp/idx && mv /tmp/idx "$VAULT/brain/retros/_Retros.md"
```
Format de la ligne : `| AAAA-MM-JJ hh:mm | Projet | [[AAAA-MM-JJ-hhmm]] , <friction ⭐ ou fait clé en ~15-25 mots, notes /5 si utile> |`. **≤ ~220 caractères.** Le détail vit dans la rétro, pas dans l'index, c'est ce qui garde l'index bon marché à relire.

## 6. Réponds
4-5 lignes : note globale, friction la plus coûteuse, leçon n°1. Concis.

**Garde-fous :** préserve frontmatter et contenu existants ; wikilinks valides ; rien hors du vault ; lectures ciblées (jamais les fichiers entiers).
