# model-router.zsh : étudie la mission annoncée à l'ouverture de session, puis choisit
# le modèle (haiku / sonnet / opus) ET le niveau d'effort (low → max), pour ne pas
# brûler d'Opus ni de réflexion sur des tâches légères.
#
# Étude en 2 temps : 1) mots-clés (instantané, gratuit) ; 2) si la mission est ambiguë,
# un mini-appel Haiku (~2 s, effort low, sans hooks) la lit et tranche. Repli sur sonnet/medium.
#
# Usage :
#   claude                     → demande la mission, l'étudie, lance claude SANS l'envoyer (texte dans le presse-papiers, ⌘V)
#   CLAUDE_ROUTER_SEND=1       → envoie la mission comme premier prompt (ancien comportement)
#   claude "ma mission"        → idem sans la question
#   claude "@o ma mission"     → force opus (@s sonnet, @h haiku)
#   claude "!x ma mission"     → force l'effort (!l low, !m medium, !h high, !x xhigh, !max max)
#   claude-route "texte"       → dry-run : affiche modèle + effort choisis sans lancer
#   CLAUDE_ROUTER_STUDY=0      → désactive l'étude Haiku (mots-clés seulement)
#   command claude ...         → bypass total du routeur
# Tout appel avec un flag (-c, --resume, -p, --model…) ou une sous-commande passe tel quel.

# Mots-clés normalisés (minuscules, ponctuation → espace). Un « * » final = préfixe.
_CR_OPUS=(
  architecture archi 'refacto*' 'refactor*' 'migration*' "from scratch" "de zero" "de zéro"
  "nouveau projet" "nouvelle app" kickoff 'strategi*' 'stratégi*' "business plan" roadmap
  "en profondeur" 'approfondi*' 'réfléchi*' 'reflechi*' 'audit*' sécurité securite security
  conception concevoir "design system" "plan détaillé" "plan detaille" 'arbitr*' décision decision
  "race condition" "fuite mémoire" "memory leak" 'algorithm*' 'algorithme*'
  "toute l app" "tout le projet" codebase "revue de code" "code review" "pourquoi ça plante"
  "comprends pas pourquoi" complexe compliqué complique pitch "étude de marché"
)
_CR_HAIKU=(
  "c est quoi" "qu est ce que" "que veut dire" "ça veut dire" définition definition
  'tradui*' 'translat*' 'reformul*' orthographe fautes typo "résume" "resume" "résumé"
  combien "quelle heure" "quel jour" 'renomme*' rename 'convertis*' 'convert*' "quelle commande"
  "commande pour" "rappelle moi" "où est" "ou est" "trouve le fichier" "question rapide"
  "vite fait" "petite question" "juste" "oui ou non" "git status" "liste les" "ouvre"
)
_CR_SONNET=(
  'code*' 'fix*' 'bug*' 'script*' 'fonction*' 'composant*' 'page*' 'mail*' 'post*' linkedin dm écris ecris
  'rédige*' 'redige*' 'ajoute*' 'modifie*' 'implément*' 'implement*' 'test*' 'build*' 'deploy*' 'déploi*'
  supabase notion browser navigateur 'relance*' api endpoint css html react swift ios app
)

_cr_hit() {  # _cr_hit "<texte normalisé>" kw... → affiche le 1er mot-clé trouvé
  local s=$1 kw; shift
  for kw in "$@"; do
    if [[ $kw == *'*' ]]; then [[ $s == *" ${kw%\*}"* ]] && { print -r -- "${kw%\*}"; return 0; }
    else [[ $s == *" $kw "* ]] && { print -r -- "$kw"; return 0; }; fi
  done
  return 1
}

# Mots-clés qui montent l'effort d'un cran de plus (travail long, risqué ou transverse)
_CR_XHIGH=(
  architecture archi 'migration*' "from scratch" "de zero" "de zéro" 'audit*' sécurité securite security
  "race condition" "fuite mémoire" "memory leak" "toute l app" "tout le projet" codebase
  "pourquoi ça plante" "comprends pas pourquoi" 'strategi*' 'stratégi*' "business plan"
)

_cr_eff() {  # normalise un alias d'effort
  case $1 in
    l|low) print low ;; m|med|medium) print medium ;; h|high) print high ;;
    x|xhigh) print xhigh ;; max) print max ;; *) return 1 ;;
  esac
}

# _cr_study "<mission>" → "modèle|effort" via un mini-appel Haiku, vide si indisponible
_cr_study() {
  [[ ${CLAUDE_ROUTER_STUDY:-1} == 0 ]] && return 1
  local out
  out=$(print -r -- "Tu routes une mission pour Claude Code. Choisis le modèle et l'effort les moins chers qui suffisent.
Modèles : haiku (question/lookup/reformulation simple), sonnet (code, édition, rédaction, tâche claire), opus (conception, bug obscur, décision, multi-fichiers, long/risqué).
Effort : low (trivial), medium (standard), high (raisonnement soutenu), xhigh (très complexe), max (exceptionnel, rare).
Réponds UNIQUEMENT par : modèle effort (ex: sonnet medium).
Mission : ${1[1,1500]}" | timeout 20 command claude -p --model haiku --effort low --no-session-persistence \
      --disable-slash-commands --strict-mcp-config --mcp-config '{"mcpServers":{}}' --setting-sources "" 2>/dev/null) || return 1
  out=${(L)out}
  local m e
  m=${${(M)${(z)out}:#(haiku|sonnet|opus)}[1]}; e=${${(M)${(z)out}:#(low|medium|high|xhigh|max)}[1]}
  [[ -n $m && -n $e ]] && print "$m|$e"
}

# _cr_classify "<mission>" → "modèle|effort|raison"
_cr_classify() {
  local raw=$1 fm fe
  # drapeaux de forçage en tête : @o/@s/@h (modèle), !l/!m/!h/!x/!max (effort)
  while [[ $raw =~ '^(@(o|opus|s|sonnet|h|haiku)|![a-z]+) ' ]]; do
    local tok=${raw%% *}
    case $tok in
      @o|@opus) fm=opus ;; @s|@sonnet) fm=sonnet ;; @h|@haiku) fm=haiku ;;
      !*) fe=$(_cr_eff ${tok#!}) || break ;;
    esac
    raw=${raw#* }
  done
  local s=" ${(L)${raw//[^[:alnum:]]/ }} " kw
  local model effort why

  if [[ -n $fm && -n $fe ]]; then print "$fm|$fe|forcé"; return; fi

  if kw=$(_cr_hit "$s" $_CR_OPUS); then
    model=opus; why="« $kw »"
    if _cr_hit "$s" $_CR_XHIGH >/dev/null; then effort=xhigh; else effort=high; fi
  elif (( ${#raw} > 600 )); then
    model=opus; effort=high; why="mission longue"
  else
    local sk hk
    sk=$(_cr_hit "$s" $_CR_SONNET); hk=$(_cr_hit "$s" $_CR_HAIKU)
    if [[ -n $hk && -z $sk && ${#raw} -lt 200 ]]; then model=haiku; effort=low; why="« $hk »"
    elif [[ -z $sk && ${#raw} -lt 60 && $raw == *'?'* ]]; then model=haiku; effort=low; why="question courte"
    elif [[ -n $sk ]]; then
      model=sonnet; why="« $sk »"
      (( ${#raw} > 300 )) && effort=high || effort=medium
    else
      # ambiguë : on fait lire la mission par Haiku avant de trancher
      local st; st=$(_cr_study "$raw")
      if [[ -n $st ]]; then model=${st%%|*}; effort=${st#*|}; why="étudiée par haiku"
      else model=sonnet; effort=medium; why="par défaut"; fi
    fi
  fi
  [[ -n $fm ]] && { model=$fm; why="modèle forcé"; }
  [[ -n $fe ]] && { effort=$fe; why="$why, effort forcé"; }
  print "$model|$effort|$why"
}

claude-route() { _cr_classify "$*" | tr '|' '\t'; }

claude() {
  [[ ${CLAUDE_ROUTER:-1} == 0 ]] && { command claude "$@"; return; }
  local a
  for a in "$@"; do [[ $a == -* ]] && { command claude "$@"; return; }; done
  case $1 in
    agents|attach|auth|auto-mode|doctor|gateway|import|install|logs|mcp|plugin|project|\
    respawn|rm|setup-token|stop|ultrareview|update) command claude "$@"; return ;;
  esac

  local mission="$*"
  if [[ -z $mission ]]; then
    # vared (zle) : pas la limite de 1024 car. du mode canonique du tty, les longs collages passent
    vared -p "🎯 Mission (sert juste à choisir modèle + effort, Entrée = sans routage) : " mission
    [[ -z $mission ]] && { command claude; return; }
  fi

  print -P "%F{8}⏳ étude de la mission…%f"
  local res model effort why rest
  res=$(_cr_classify "$mission"); model=${res%%|*}; rest=${res#*|}; effort=${rest%%|*}; why=${rest#*|}
  while [[ $mission =~ '^(@(o|opus|s|sonnet|h|haiku)|![a-z]+) ' ]]; do mission=${mission#* }; done
  print -P "%F{cyan}→ ${model} · effort ${effort}%f %F{8}(${why}) · « @o/@s/@h » et « !l/!m/!h/!x/!max » pour forcer, /model et /effort en cours de route%f"
  if [[ ${CLAUDE_ROUTER_SEND:-0} == 1 ]]; then
    command claude --model "$model" --effort "$effort" "$mission"
  else
    # La mission n'est PAS envoyée : elle est dans le presse-papiers (⌘V) pour que tu la développes
    print -rn -- "$mission" | pbcopy
    print -P "%F{8}📋 mission copiée, ⌘V pour la coller dans le prompt et la développer (rien n'est envoyé)%f"
    command claude --model "$model" --effort "$effort"
  fi
}
