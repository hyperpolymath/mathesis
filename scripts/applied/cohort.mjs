// SPDX-License-Identifier: MPL-2.0
// SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell
//
// The worked examples of the cohort model (re-anchoring plan WO 4.2).
//
// Each file in applied-systems/finance/cohort-economics/examples/ is one
// synthetic worked example: an example record, its cohorts, its inputs (in
// the shared input schema, inputs.mjs) and the expected outputs. This script
// validates each example and writes two views of it:
//
//   verification/proofs/agda/Applied/Example/<Name>.agda
//     the inputs as Agda terms, and one check for each expected output. Agda
//     runs the model (Applied.Cohort) and accepts the module only if every
//     expected output, missing ones included, is what the model computes.
//   applied-systems/finance/cohort-economics/generated/examples.adoc
//     the inputs and the expected outputs as tables.
//
// usage: bun scripts/applied/cohort.mjs build | check

import {readFile, writeFile, readdir, mkdir} from 'node:fs/promises';
import {fileURLToPath} from 'node:url';
import path from 'node:path';
import {parseJsonl} from '../atlas/census-atlas.mjs';
import {validateInput} from './inputs.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
export const EXAMPLES = 'applied-systems/finance/cohort-economics/examples';
export const VIEW = 'applied-systems/finance/cohort-economics/generated/examples.adoc';
export const AGDA_DIR = 'verification/proofs/agda/Applied/Example';

export const MODES = ['simple', 'approximate', 'exact'];
const COMMON = {
  opening_cash: 'pence', price: 'pence per member per period', unit_cost: 'pence per member per period',
  support_minutes: 'minutes per member per period',
};
const PER_PERIOD = {fixed_cost: 'pence', cash_floor: 'pence', capacity_minutes: 'minutes'};
const ROW_OUTPUTS = ['members', 'receipts', 'payments', 'closing', 'shortfall', 'hours', 'cash_ok', 'capacity_ok'];
const SUMMARY_OUTPUTS = new Set(['cash_verdict', 'capacity_verdict', 'gap']);
const TRUTHS = new Set(['cash_ok', 'capacity_ok', 'cash_verdict', 'capacity_verdict']);
const SYNTHETIC = new Set(['illustrative', 'missing']);
const EXAMPLE_FIELDS = ['description', 'kind', 'mode', 'name', 'period_length', 'periods', 'synthetic', 'title'];
const COHORT_FIELDS = ['description', 'id', 'kind', 'start'];
const EXPECTED_FIELDS = ['evidence_status', 'id', 'kind', 'period', 'value'];

const keyOf = (id, period) => `${id}@${period}`;
const need = (ok, message) => {
  if (!ok) throw new Error(message);
};
const text = v => typeof v === 'string' && v.trim() !== '';
const closed = (r, fields, where) => {
  for (const k of Object.keys(r)) need(fields.includes(k), `${where}: unknown field ${k}`);
  for (const k of fields) need(k in r, `${where}: missing field ${k}`);
};
const natural = v => Number.isSafeInteger(v) && v >= 0;

// A number as an exact fraction {n, d} of BigInts, d > 0: an integer, a
// decimal string or a fraction string "n/d".
export function parseNumber(v, where) {
  if (Number.isSafeInteger(v)) return {n: BigInt(v), d: 1n};
  need(typeof v === 'string', `${where}: a number is an integer, a decimal string or "n/d"`);
  let m = /^(-?)(\d+)\.(\d+)$/.exec(v);
  if (m) return {n: BigInt(m[1] + m[2] + m[3]), d: 10n ** BigInt(m[3].length)};
  m = /^(-?\d+)\/([1-9]\d*)$/.exec(v);
  need(m, `${where}: ${JSON.stringify(v)} is not an integer, a decimal string or "n/d"`);
  return {n: BigInt(m[1]), d: BigInt(m[2])};
}

function validateHeader(ex, name) {
  need(ex?.kind === 'example', `${name}: the first record is the example record`);
  closed(ex, EXAMPLE_FIELDS, `${name}: example`);
  need(ex.name === name, `${name}: the example name matches the file name`);
  need(MODES.includes(ex.mode), `${name}: mode is one of ${MODES.join(', ')}`);
  need(ex.synthetic === true, `${name}: a public example is synthetic by construction`);
  for (const k of ['title', 'description', 'period_length']) need(text(ex[k]), `${name}: ${k} is text`);
  need(Array.isArray(ex.periods) && ex.periods.length > 0 && ex.periods.every(text), `${name}: periods lists period labels`);
  need(new Set(ex.periods).size === ex.periods.length, `${name}: period labels are unique`);
}

function addCohort(acc, r, where) {
  closed(r, COHORT_FIELDS, where);
  need(/^[A-Z][A-Za-z0-9]*$/.test(r.id), `${where}: a cohort id is a capitalised name`);
  need(acc.periodIndex.has(r.start), `${where}: start is a period label`);
  need(text(r.description), `${where}: description is text`);
  need(!acc.cohorts.some(c => c.id === r.id), `${where}: duplicate cohort ${r.id}`);
  acc.cohorts.push(r);
}

function addInput(acc, r, where) {
  validateInput(r, where);
  need(r.access === 'public', `${where} (${r.id}): Mathesis holds public inputs only`);
  need(SYNTHETIC.has(r.evidence_status),
    `${where} (${r.id}): a synthetic input is illustrative (or missing); it is not evidence about an organisation`);
  const key = `${r.id}@${r.period}`;
  need(!acc.inputs.has(key), `${where}: duplicate input ${key}`);
  acc.inputs.set(key, r);
}

function addExpected(acc, r, where) {
  closed(r, EXPECTED_FIELDS, where);
  const isRow = ROW_OUTPUTS.includes(r.id);
  need(isRow || SUMMARY_OUTPUTS.has(r.id), `${where}: unknown output ${r.id}`);
  const periodOk = isRow ? acc.periodIndex.has(r.period) : r.period === null;
  need(periodOk, `${where} (${r.id}): period is ${isRow ? 'a period label' : 'null'}`);
  need(SYNTHETIC.has(r.evidence_status), `${where} (${r.id}): an output of synthetic inputs is illustrative or missing`);
  need((r.evidence_status === 'missing') === (r.value === null), `${where} (${r.id}): a missing output has the value null, and only a missing one`);
  if (r.value !== null && TRUTHS.has(r.id)) need(typeof r.value === 'boolean', `${where} (${r.id}): the value is true or false`);
  if (r.value !== null && !TRUTHS.has(r.id)) parseNumber(r.value, `${where} (${r.id})`);
  const key = `${r.id}@${r.period}`;
  need(!acc.expected.has(key), `${where}: duplicate expected output ${key}`);
  acc.expected.set(key, r);
}

const ADD = {cohort: addCohort, input: addInput, expected: addExpected};

// The inputs that a mode reads, each with its unit and the form of its value.
function wantedInputs(ex, cohorts, periodIndex) {
  const wanted = new Map();
  for (const [id, unit] of Object.entries(COMMON)) wanted.set(`${id}@null`, {unit, form: 'integer'});
  for (const [id, unit] of Object.entries(PER_PERIOD)) for (const p of ex.periods) wanted.set(`${id}@${p}`, {unit, form: 'integer'});
  const rate = ex.mode === 'approximate' ? {unit: 'per 1000', form: 'permille'} : {unit: 'fraction', form: 'fraction'};
  for (const c of cohorts) {
    if (ex.mode === 'simple') {
      for (const p of ex.periods.slice(periodIndex.get(c.start) - 1)) wanted.set(`${c.id}.active@${p}`, {unit: 'members', form: 'natural'});
    } else {
      wanted.set(`${c.id}.contacts@null`, {unit: 'people', form: 'natural'});
      wanted.set(`${c.id}.conversion@null`, rate);
      wanted.set(`${c.id}.retention@null`, rate);
    }
  }
  return wanted;
}

const fractionUpToOne = v => {
  const m = typeof v === 'string' && /^(\d+)\/([1-9]\d*)$/.exec(v);
  return Boolean(m) && BigInt(m[1]) <= BigInt(m[2]);
};
const FORMS = {
  integer: [Number.isSafeInteger, 'an integer'],
  natural: [natural, 'a whole number'],
  permille: [v => natural(v) && v <= 1000, 'a whole number from 0 to 1000'],
  fraction: [fractionUpToOne, 'a fraction "n/d" from 0 to 1'],
};

// Throw unless the records form one valid worked example; return it.
export function validateExample(records, name) {
  const ex = records[0];
  validateHeader(ex, name);
  const acc = {periodIndex: new Map(ex.periods.map((p, i) => [p, i + 1])), cohorts: [], inputs: new Map(), expected: new Map()};
  for (const [i, r] of records.slice(1).entries()) {
    const where = `${name}: record ${i + 2}`;
    need(Object.hasOwn(ADD, r.kind), `${where}: kind is cohort, input or expected`);
    ADD[r.kind](acc, r, where);
  }
  need(acc.cohorts.length > 0, `${name}: at least one cohort`);
  const wanted = wantedInputs(ex, acc.cohorts, acc.periodIndex);
  for (const key of acc.inputs.keys()) need(wanted.has(key), `${name}: input ${key} is not read in mode ${ex.mode}`);
  for (const [key, w] of wanted) {
    const r = acc.inputs.get(key);
    need(r, `${name}: input ${key} is absent; a missing input is a record with the value null`);
    need(r.unit === w.unit, `${name}: input ${key} has the unit "${w.unit}"`);
    const [ok, form] = FORMS[w.form];
    need(r.value === null || ok(r.value), `${name}: input ${key} is ${form}`);
  }
  for (const p of ex.periods) for (const id of ROW_OUTPUTS) need(acc.expected.has(`${id}@${p}`), `${name}: no expected ${id} for ${p}`);
  for (const id of SUMMARY_OUTPUTS) need(acc.expected.has(`${id}@null`), `${name}: no expected ${id}`);
  return {ex, ...acc};
}

// ---------------------------------------------------------------- Agda view

const agdaInt = n => (n >= 0n ? `pos ${n}` : `negsuc ${-n - 1n}`);
const status = r => (r.evidence_status === 'missing' ? null : r.evidence_status);
const val = (r, term) => (r.value === null ? 'missing' : `given ${status(r)} ${term(r.value)}`);
const paren = s => (s.includes(' ') ? `(${s})` : s);
const list = items => (items.length ? `${items.map(paren).join(' ∷ ')} ∷ []` : '[]');
const rate = (mode, v) => (mode === 'approximate' ? `(perMille ${v})` : `(fraction ${v.replaceAll('/', ' ')})`);
const AGDA_FIELD = {
  members: 'members', receipts: 'receipts', payments: 'payments', closing: 'closing', shortfall: 'shortfall',
  hours: 'hours', cash_ok: 'cashOk', capacity_ok: 'capacityOk', cash_verdict: 'cashVerdict',
  capacity_verdict: 'capacityVerdict', gap: 'gap',
};

function expect(r) {
  if (r.value === null) return 'absent';
  if (typeof r.value === 'boolean') return `(truth ${r.evidence_status} ${r.value})`;
  const {n, d} = parseNumber(r.value, r.id);
  return `(number ${r.evidence_status} (${agdaInt(n)}) ${d})`;
}

export const moduleName = name => name[0].toUpperCase() + name.slice(1);

export function renderAgda(v, source) {
  const {ex, cohorts, inputs, expected, periodIndex} = v;
  const get = key => inputs.get(key);
  const money = key => val(get(key), x => `(${agdaInt(BigInt(x))})`);
  const perPeriod = id => list(ex.periods.map(p => money(`${id}@${p}`)));
  const cohortTerm = c => {
    const start = periodIndex.get(c.start);
    if (ex.mode === 'simple') {
      const counts = ex.periods.slice(start - 1).map(p => val(get(keyOf(`${c.id}.active`, p)), String));
      return `observed ${start} (${list(counts)})`;
    }
    const contacts = val(get(keyOf(`${c.id}.contacts`, null)), String);
    const r = key => val(get(key), x => rate(ex.mode, x));
    const conversion = paren(r(keyOf(`${c.id}.conversion`, null)));
    const retention = paren(r(keyOf(`${c.id}.retention`, null)));
    return `modelled ${start} ${paren(contacts)} ${conversion} ${retention}`;
  };
  const out = [
    '{-# OPTIONS --safe --without-K --cubical-compatible #-}',
    '-- SPDX-License-Identifier: MPL-2.0',
    `-- Generated by scripts/applied/cohort.mjs from ${source}.`,
    '-- Do not edit: change the example and run `just applied-build`.',
    '--',
    `-- ${ex.title} (mode ${ex.mode}). Agda accepts this module only if the`,
    '-- model computes every expected output below, missing ones included.',
    '',
    `module Applied.Example.${moduleName(ex.name)} where`,
    '',
    'open import Agda.Builtin.Bool using (Bool; true; false)',
    'open import Agda.Builtin.Equality using (_≡_; refl)',
    'open import Agda.Builtin.Int using (pos; negsuc)',
    'open import Agda.Builtin.List using (_∷_; [])',
    'open import Applied.Cohort',
    'open import Applied.IntNumber',
    '',
    'inputs : Inputs',
    'inputs = record',
    `  { periods  = ${ex.periods.length}`,
    `  ; opening  = ${money('opening_cash@null')}`,
    `  ; price    = ${money('price@null')}`,
    `  ; unitCost = ${money('unit_cost@null')}`,
    `  ; minutes  = ${money('support_minutes@null')}`,
    `  ; fixed    = ${perPeriod('fixed_cost')}`,
    `  ; floor    = ${perPeriod('cash_floor')}`,
    `  ; capacity = ${perPeriod('capacity_minutes')}`,
    `  ; cohorts  = ${list(cohorts.map(cohortTerm))}`,
    '  }',
    '',
    'result : Result',
    'result = run inputs',
  ];
  for (const p of ex.periods) {
    out.push('', `-- Period ${p}`);
    for (const id of ROW_OUTPUTS) {
      const e = expect(expected.get(keyOf(id, p)));
      out.push(`_ : check result ${periodIndex.get(p)} ${AGDA_FIELD[id]} ${e} ≡ true`, '_ = refl');
    }
  }
  out.push('', '-- Over all periods');
  for (const id of SUMMARY_OUTPUTS) {
    const e = expect(expected.get(keyOf(id, null)));
    out.push(`_ : checkSummary result ${AGDA_FIELD[id]} ${e} ≡ true`, '_ = refl');
  }
  return out.join('\n') + '\n';
}

// --------------------------------------------------------------- AsciiDoc view

const cell = s => String(s).replaceAll('|', String.raw`\|`).replaceAll('\n', ' ');
const shown = r => {
  if (r.value === null) return '_missing_';
  if (r.value === true) return 'yes';
  if (r.value === false) return 'no';
  return String(r.value);
};

export function renderView(examples) {
  const out = [
    '// SPDX-License-Identifier: CC-BY-SA-4.0',
    '// Generated by scripts/applied/cohort.mjs from the files in examples/. Do not edit.',
    '= Cohort model: worked examples',
    '',
    'Each example is synthetic and illustrative. Agda checks every output below',
    'against the model (`verification/proofs/agda/Applied/Cohort.agda`); a missing',
    'value stays missing. Money is in pence. link:../modes.adoc[The number modes]',
    'say which mode to use.',
  ];
  for (const {ex, cohorts, inputs, expected} of examples) {
    out.push('', `== ${ex.title}`, '', `Mode: \`${ex.mode}\`. Periods: ${ex.periods.join(', ')} (${ex.period_length}).`, '', ex.description, '');
    out.push('Cohorts:', '', ...cohorts.map(c => `* ${c.id}, from ${c.start}: ${c.description}`));
    out.push('', '.Inputs', '[cols="2,1,2,1,1",options="header"]', '|===', '|Input |Period |Unit |Value |Status', '');
    for (const r of inputs.values()) {
      out.push(`|${cell(r.description)} (\`${r.id}\`)`, `|${r.period ?? 'all'}`, `|${cell(r.unit)}`, `|${cell(shown(r))}`, `|${r.evidence_status}`, '');
    }
    out.push('|===', '', '.Outputs', '[cols="1,1,1,1,1,1,1,1,1",options="header"]', '|===',
      '|Period |Members |Receipts |Payments |Closing cash |Shortfall below floor |Support minutes |Floor met |Capacity met', '');
    for (const p of ex.periods) {
      out.push(`|${p}`, ...ROW_OUTPUTS.map(id => `|${cell(shown(expected.get(keyOf(id, p))))}`), '');
    }
    out.push('|===', '');
    const s = id => shown(expected.get(`${id}@null`));
    out.push(`Floor met in every period: ${s('cash_verdict')}. Capacity met in every period: ${s('capacity_verdict')}. ` +
      `Funding gap (the least addition to the opening cash that meets every floor): ${s('gap')}.`);
  }
  return out.join('\n') + '\n';
}

// ---------------------------------------------------------------------- CLI

export async function loadExamples() {
  const files = (await readdir(path.join(root, EXAMPLES))).filter(f => f.endsWith('.jsonl')).sort();
  need(files.length > 0, `${EXAMPLES}: no examples`);
  return Promise.all(files.map(async f => {
    const rel = `${EXAMPLES}/${f}`;
    const records = parseJsonl(await readFile(path.join(root, rel), 'utf8'), rel);
    return {rel, v: validateExample(records, path.basename(f, '.jsonl'))};
  }));
}

export async function views() {
  const examples = await loadExamples();
  const files = new Map(examples.map(({rel, v}) => [`${AGDA_DIR}/${moduleName(v.ex.name)}.agda`, renderAgda(v, rel)]));
  files.set(VIEW, renderView(examples.map(e => e.v)));
  return files;
}

async function write(rel, body) {
  const file = path.join(root, rel);
  await mkdir(path.dirname(file), {recursive: true});
  await writeFile(file, body);
}

async function current(rel, body) {
  const now = await readFile(path.join(root, rel), 'utf8').catch(() => null);
  need(now === body, `${rel} is stale; run: just applied-build`);
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const [cmd] = process.argv.slice(2);
  try {
    need(cmd === 'build' || cmd === 'check', 'usage: cohort.mjs build | check');
    const files = await views();
    const onDisk = (await readdir(path.join(root, AGDA_DIR)).catch(() => [])).map(f => `${AGDA_DIR}/${f}`).filter(f => f.endsWith('.agda'));
    for (const f of onDisk) need(files.has(f), `${f} has no example; remove it or add the example`);
    await Promise.all([...files].map(([rel, body]) => (cmd === 'build' ? write(rel, body) : current(rel, body))));
    console.log(cmd === 'build' ? `wrote ${files.size} files` : `PASS: the ${files.size} generated files of the cohort examples are current`);
  } catch (e) {
    console.error('ERROR: ' + e.message);
    process.exitCode = 1;
  }
}
