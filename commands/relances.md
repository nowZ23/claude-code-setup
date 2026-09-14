---
description: "Scanne Gmail (+ agenda si dispo) pour les fils qui attendent une réponse et les liste par priorité. Lecture seule : ne répond ni n'envoie rien."
---

Sors la **liste des relances / réponses en attente**, ce qui risque de « passer à travers les mailles ». **Lecture seule** : tu ne rédiges ni n'envoies aucune réponse, tu ne fais que détecter et prioriser.

Argument optionnel (`$ARGUMENTS`) : une fenêtre (`7j`, `30j`) ou un filtre (`clients`, `perso`). Défaut : **14 jours**.

## 1. Détecte (économe, requêtes ciblées, pas de dump)
Via le MCP Gmail :
- Cherche les fils de l'inbox **récents** où **le dernier message n'est PAS de toi** (une réponse est donc attendue). Bonnes requêtes de départ : `in:inbox -from:me newer_than:14d` et `is:unread in:inbox`.
- **Écarte** le bruit : newsletters, notifications, no-reply, promos, réseaux sociaux (`-category:promotions -category:social -from:noreply`).
- Ne lis le fil en entier (`get_thread`) **que si** le sujet seul ne suffit pas à juger, jamais tous les fils par défaut.
- Si le MCP **Microsoft 365 / agenda** est connecté : ajoute les **RDV des 7 prochains jours** qui demandent une préparation ou une confirmation.

## 2. Contextualise (léger)
Pour chaque expéditeur, un `grep` rapide du vault (`org/people/`, `work/active/`) pour savoir qui c'est et l'enjeu, **sans** lire des notes entières. Si inconnu, laisse « ? ».

## 3. Sors le tableau (priorisé)
Trie par **urgence × enjeu** (client/partenaire/argent > perso > FYI). Format :

| Priorité | Qui | Sujet | Attend depuis | Enjeu / contexte | Action suggérée |
|---|---|---|---|---|---|

Termine par **la seule chose à faire en premier** (une ligne). Ne propose de rédiger une réponse que si on te le demande et alors applique ta voix + tes vérifications habituelles.

## 4. (Option) En routine
Si tu veux ça chaque matin : proposer `/loop` ou le skill `schedule` (ex. tous les jours 8h). **Ne rien planifier sans accord** (règle : une automatisation persistante se propose, ne se construit pas d'office).

**Garde-fous :** lecture seule ; aucune réponse envoyée ; requêtes ciblées, jamais l'inbox entière chargée ; ne logge pas le contenu des mails dans le vault sauf demande explicite.
