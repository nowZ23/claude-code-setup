#!/usr/bin/env node
// Garde-fou typographie FR — exemple de hook de contrôle de style.
// Portée VOLONTAIREMENT étroite : uniquement les LIVRABLES rédactionnels FR
// (mails, posts, DM), pas la prose de conversation ni les notes du vault.
//
//   --stop        : hook Stop. Extrait du dernier message assistant les zones de
//                   draft (blocs ``` et blockquotes >) et bloque si faute.
//   --posttooluse : hook PostToolUse Write/Edit. Contrôle les .md/.txt écrits
//                   HORS vault (un draft posé sur disque).
//
// Les règles ci-dessous (tiret cadratin, virgule avant et/ou, deux-points
// collés, emoji) sont un EXEMPLE de préférences personnelles — remplace-les
// par les tiennes.

import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';

const MODE = process.argv.includes('--posttooluse') ? 'post' : 'stop';

function vaultPath() {
  try {
    const p = fs.readFileSync(path.join(os.homedir(), '.claude', 'obsidian-vault.path'), 'utf8').trim();
    if (p) return p;
  } catch {}
  return null; // pas de vault configuré : voir README
}
const VAULT = vaultPath();
const ok = () => process.exit(0);

let data = {};
try { data = JSON.parse(fs.readFileSync(0, 'utf8')); } catch { ok(); }

// --- utilitaires ------------------------------------------------------------
const FR_RE = /\b(le|la|les|des|une|un|du|aux|je|tu|il|elle|nous|vous|pour|avec|dans|sur|est|sont|que|qui|pas|plus|mais|donc|cette|c'est|j'ai|ton|ta|tes|te|si|ce)\b/gi;
const frScore = t => (t.match(FR_RE) || []).length;

function clean(t) {
  return t
    .replace(/^---\n[\s\S]*?\n---\n/, ' ')
    .replace(/`[^`\n]*`/g, ' ')
    .replace(/https?:\/\/\S+/g, ' ')
    .replace(/\[\[[^\]]*\]\]/g, ' ')
    .replace(/\]\([^)]*\)/g, '] ')
    .replace(/[\w./~@-]+\.[a-zA-Z]{1,5}:\d+/g, ' ');
}

// --- 1. récupérer les zones à contrôler ------------------------------------
function lastAssistantText(p) {
  if (!p || !fs.existsSync(p)) return '';
  let out = '';
  for (const line of fs.readFileSync(p, 'utf8').split('\n')) {
    if (!line.trim()) continue;
    let e; try { e = JSON.parse(line); } catch { continue; }
    const m = e.message || e;
    if ((m.role || e.type) !== 'assistant') continue;
    const c = m.content;
    let t = '';
    if (typeof c === 'string') t = c;
    else if (Array.isArray(c)) t = c.filter(x => x && x.type === 'text' && x.text).map(x => x.text).join('\n');
    if (t.trim()) out = t;
  }
  return out;
}

// Zones de draft = blocs ``` (sans langage de code) + suites de lignes « > ».
function draftZones(msg) {
  const zones = [];
  for (const m of msg.matchAll(/```([a-zA-Z0-9_-]*)\n([\s\S]*?)```/g)) {
    const lang = (m[1] || '').toLowerCase();
    if (lang && !/^(text|txt|markdown|md|email|mail|post)$/.test(lang)) continue; // vrai code
    zones.push(m[2]);
  }
  let buf = [];
  for (const line of msg.split('\n')) {
    if (/^\s*>/.test(line)) buf.push(line.replace(/^\s*>\s?/, ''));
    else { if (buf.length >= 2) zones.push(buf.join('\n')); buf = []; }
  }
  if (buf.length >= 2) zones.push(buf.join('\n'));
  return zones;
}

let chunks = [], where = '';
if (MODE === 'stop') {
  if (data.stop_hook_active) ok();
  const msg = lastAssistantText(data.transcript_path);
  if (!msg) ok();
  chunks = draftZones(msg);
  where = 'le draft que tu viens de montrer';
} else {
  if (!/^(Write|Edit|NotebookEdit)$/.test(data.tool_name || '')) ok();
  const ti = data.tool_input || {};
  const fp = ti.file_path || '';
  if (!/\.(md|txt|markdown)$/i.test(fp)) ok();
  if (VAULT && fp.startsWith(VAULT)) ok();              // notes internes : hors périmètre
  chunks = [ti.content || ti.new_string || ''];
  where = fp;
}

chunks = chunks.map(clean).filter(t => t.length > 60 && frScore(t) >= 6);
if (!chunks.length) ok();

// --- 2. contrôles -----------------------------------------------------------
const hard = [], soft = [];
for (const t of chunks) {
  const snip = (i, j) => t.slice(Math.max(0, i - 45), j + 20).replace(/\s+/g, ' ').trim();
  for (const m of t.matchAll(/[—–]/g)) hard.push(`TIRET CADRATIN , « ...${snip(m.index, m.index + 1)}... »`);
  for (const m of t.matchAll(/,\s+(et|ou)\b/g)) hard.push(`VIRGULE AVANT ET/OU , « ...${snip(m.index, m.index + m[0].length)}... »`);
  for (const m of t.matchAll(/(\S):(?!\/)/g)) {
    const i = m.index;
    if (m[1] === ':') continue;
    if (/\d/.test(m[1]) && /\d/.test(t[i + 2] || '')) continue;
    hard.push(`DEUX-POINTS COLLÉS , « ...${snip(i, i + 2)}... »`);
  }
  for (const ch of t) {
    if (ch.codePointAt(0) > 0x2190 && /\p{Emoji_Presentation}/u.test(ch)) { soft.push(`EMOJI dans un livrable , ${ch}`); break; }
  }
}
if (!hard.length && !soft.length) ok();

const uniq = a => [...new Set(a)].slice(0, 8);
const reason =
  `Contrôle typographie FR sur ${where} , ${hard.length} faute(s) dure(s) :\n` +
  uniq([...hard, ...soft]).map(l => '  · ' + l).join('\n') +
  `\n\nRègles de style (exemple, à personnaliser) : jamais de tiret cadratin (virgule ou point), jamais de virgule avant « et »/« ou », toujours un espace avant les deux points, pas d'emoji dans un livrable.` +
  (MODE === 'stop' ? `\nRedonne la version corrigée du draft, sans commentaire méta.` : `\nCorrige le fichier avant de continuer.`);

if (!hard.length) { console.error(reason); process.exit(0); }   // emoji seul : simple info
if (MODE === 'stop') { console.log(JSON.stringify({ decision: 'block', reason })); process.exit(0); }
console.log(JSON.stringify({ hookSpecificOutput: { hookEventName: 'PostToolUse', additionalContext: reason } }));
