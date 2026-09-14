#!/usr/bin/env node
// Stop hook (global). Détecte la clôture d'une session, calcule des métriques
// objectives depuis le transcript, et déclenche UNE fois la rétro de session.
// N'écrit rien dans le vault lui-même : il instruit Claude (decision: block) à le faire.

import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';

function exit0() { process.exit(0); }

let raw = '';
try { raw = fs.readFileSync(0, 'utf8'); } catch { exit0(); }
let data = {};
try { data = JSON.parse(raw); } catch { exit0(); }

const { session_id, transcript_path, cwd, stop_hook_active } = data;
// Évite la boucle : si on est déjà en train de continuer suite à ce hook, on sort.
if (stop_hook_active) exit0();
if (!session_id || !transcript_path || !fs.existsSync(transcript_path)) exit0();

let VAULT = path.join(os.homedir(), 'Documents', 'Claude', 'obsidian-mind');
try { const p = fs.readFileSync(path.join(os.homedir(), '.claude', 'obsidian-vault.path'), 'utf8').trim(); if (p) VAULT = p; } catch {}

const markerDir = path.join(os.homedir(), '.claude', '.session-retro');
try { fs.mkdirSync(markerDir, { recursive: true }); } catch {}
const doneFile = path.join(markerDir, `${session_id}.done`);
if (fs.existsSync(doneFile)) exit0(); // déjà fait pour cette session

// --- Parse le transcript JSONL ---
function userText(entry) {
  const m = entry.message || entry;
  if (!m) return null;
  const role = m.role || entry.type;
  if (role !== 'user') return null;
  const c = m.content;
  if (typeof c === 'string') return c;
  if (Array.isArray(c)) {
    // ignore les tool_result (renvoyés comme messages "user")
    const texts = c.filter(p => p && p.type === 'text' && typeof p.text === 'string').map(p => p.text);
    if (texts.length === 0) return null; // probablement un tool_result, pas un vrai tour humain
    return texts.join('\n');
  }
  return null;
}

let userTurns = 0, asstTurns = 0, toolCalls = 0;
let firstTs = null, lastTs = null, lastUser = '';
const userBlob = [];

let lines = [];
try { lines = fs.readFileSync(transcript_path, 'utf8').split('\n'); } catch { exit0(); }

for (const line of lines) {
  if (!line.trim()) continue;
  let e; try { e = JSON.parse(line); } catch { continue; }
  if (e.timestamp) { const t = Date.parse(e.timestamp); if (!isNaN(t)) { if (firstTs === null) firstTs = t; lastTs = t; } }
  const m = e.message || e;
  const role = (m && m.role) || e.type;
  if (role === 'user') {
    const txt = userText(e);
    if (txt !== null) { userTurns++; lastUser = txt; userBlob.push(txt); }
  } else if (role === 'assistant') {
    asstTurns++;
    const c = m && m.content;
    if (Array.isArray(c)) toolCalls += c.filter(p => p && p.type === 'tool_use').length;
  }
}

// --- Heuristiques de déclenchement ---
const SUBSTANTIAL = userTurns >= 4;
// Limites Unicode-aware (?<![\p{L}])…(?![\p{L}]) : \b échouerait sur les accents (« à demain »).
// Ancré en fin de message ([^\p{L}]*$ = plus aucun MOT après) : un au revoir clôt le tour,
// c'est le dernier mot. Sans l'ancre, « à toute l'équipe » ou « c'est tout ça qui… »
// déclencheraient la rétro EN PLEIN travail.
const END_RE = /(?<![\p{L}])(au revoir|à demain|a demain|bonne nuit|bonne soir[ée]+e?|bonne journ[ée]+e?|c'?est (tout|bon)|on s'?arr[êe]te|on arr[êe]te (l[àa]|ici)|merci (beaucoup )?(c'?est tout|pour tout|pour aujourd)|[àa] (plus|toute)|bye|good ?night|that'?s all|we'?re done|fin de session)(?![\p{L}])[^\p{L}]*$/iu;
const isEnd = END_RE.test((lastUser || '').trim());

if (!(isEnd && SUBSTANTIAL)) exit0();

// --- Signaux de friction (sur les messages utilisateur) ---
const FRICTION_RE = /(non[, ]|pas (ça|ca|comme ça|bon|ce que)|c'?est pas|ce n'?est pas|toujours pas|encore (faux|rat[ée]|une fois)|recommence|erreur|tu t'?es tromp|wrong|that'?s not|not what i|no,? that)/gi;
const blob = userBlob.join('\n');
const frictionMatches = (blob.match(FRICTION_RE) || []);
const frictionCount = frictionMatches.length;
const frictionSample = [...new Set(frictionMatches.map(s => s.trim().toLowerCase()))].slice(0, 6);

const durationMin = (firstTs !== null && lastTs !== null) ? Math.round((lastTs - firstTs) / 60000) : null;

const metrics = {
  session_id, cwd: cwd || null,
  duration_min: durationMin,
  user_turns: userTurns, assistant_turns: asstTurns, tool_calls: toolCalls,
  friction_count: frictionCount, friction_sample: frictionSample,
  ended_at: new Date().toISOString(),
};

try {
  fs.writeFileSync(path.join(markerDir, `${session_id}.metrics.json`), JSON.stringify(metrics, null, 2));
  fs.writeFileSync(doneFile, new Date().toISOString());
} catch {}

const reason = [
  '🪞 Fin de session détectée. AVANT de clore, génère la rétrospective de cette session.',
  'Applique les instructions de `~/.claude/commands/session-retro.md`.',
  `Métriques objectives — durée: ${durationMin ?? '?'} min · tes tours: ${userTurns} · mes réponses: ${asstTurns} · appels d'outils: ${toolCalls} · signaux de friction: ${frictionCount}${frictionSample.length ? ' (' + frictionSample.join(', ') + ')' : ''}.`,
  `session_id=${session_id} · projet/cwd=${cwd || '?'}.`,
  `Écris la rétro dans ${VAULT}/brain/retros/ et distille les leçons durables dans ${VAULT}/brain/Self-Critique.md. Sois honnête et concis. Ensuite tu peux clore.`,
].join(' ');

process.stdout.write(JSON.stringify({ decision: 'block', reason }));
process.exit(0);
