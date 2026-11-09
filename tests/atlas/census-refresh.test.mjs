// SPDX-License-Identifier: MPL-2.0
// Isolated shell integration tests: real merge, fold and rendering; no network.
// Usage: bun test tests/atlas/census-refresh.test.mjs
import {test, expect, afterEach} from 'bun:test';
import {mkdtempSync, mkdirSync, cpSync, writeFileSync, readFileSync, rmSync, existsSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {join} from 'node:path';
import {spawnSync} from 'node:child_process';

const source = new URL('../../scripts/census/', import.meta.url);
const roots = [];
afterEach(() => { for (const root of roots.splice(0)) rmSync(root, {recursive:true, force:true}); });
const sha = '1234567890abcdef1234567890abcdef12345678';
const oldRow = repo => ({repo, class:'theory', own_files:9, fixture_files:0,
  provers:'agda 9', declarations:4, holes:1, axioms:0, unsafe:0, policy:0, status_doc:''});
const oldRefresh = repo => ({repo, commit:'old', refreshed:'2000-01-01'});
function fixture() {
  const root = mkdtempSync(join(tmpdir(), 'mathesis-refresh-'));
  roots.push(root);
  const scripts = join(root, 'scripts/census');
  const census = join(root, 'docs/catalogue/census');
  mkdirSync(scripts, {recursive:true});
  mkdirSync(census, {recursive:true});
  cpSync(source, scripts, {recursive:true});
  const write = (file, data) => writeFileSync(join(census, file), JSON.stringify(data)+'\n');
  const read = file => JSON.parse(readFileSync(join(census,file), 'utf8'));
  write('repos.json', ['keep','fresh','new','empty','down','template'].map(name => ({full_name:`org/${name}`,fork:false})));
  write('catalogue-rows.json', ['keep','fresh','empty','down','template'].map(name => oldRow(`org/${name}`)));
  write('unreachable.json', [{repo:'org/keep',error:'preserve',exit:7},{repo:'org/fresh',error:'old',exit:1},{repo:'org/down',error:'old',exit:1}]);
  write('refreshed.json', [oldRefresh('org/keep'),oldRefresh('org/fresh')]);
  writeFileSync(join(census,'template-paths.txt'), 'Template.agda\n');
  // Model the per-repository scanner's output contract, leaving downstream
  // summarise/build-rows/render scripts unchanged in this disposable tree.
  writeFileSync(join(scripts,'census-repo.sh'), `#!/usr/bin/env bash
set -euo pipefail
repo=$1
out="$MATHESIS_DATA/out/\u0024{repo/\\//__}"
mkdir -p "$MATHESIS_DATA/out"
case "$repo" in
  org/down) jq -cn --arg r "$repo" '{repo:$r,error:"offline",exit:128}' > "$out.unreach.jsonl"; exit 0 ;;
esac
printf '%s\\n' '${sha}' > "$out.head"
case "$repo" in
  org/empty) exit 0 ;;
  org/template) path=Template.agda ;;
  *) path=Proof.agda ;;
esac
jq -cn --arg r "$repo" --arg p "$path" '{repo:$r,path:$p,ext:"agda"}' > "$out.files.jsonl"
jq -cn --arg r "$repo" --arg p "$path" '{repo:$r,file:$p,name:"proof",kind:"sig",line:1,prover:"agda"}' > "$out.decls.jsonl"
`);
  const run = (script, args=[]) => spawnSync('bash', [join(scripts,script), ...args], {
    cwd:root, env:{...process.env, BASH_ENV:'/dev/null', MATHESIS_WORK:join(root,'work')}, encoding:'utf8', timeout:15000,
  });
  const refresh = (...names) => {
    const result = run('refresh-rows.sh',names);
    expect(result.error).toBeUndefined();
    expect(result.status, result.stderr).toBe(0);
    return result;
  };
  return {root,scripts,census,write,read,run,refresh};
}

test('refresh replaces selected rows, adds new rows, and preserves unrelated row values', () => {
  const f=fixture(), kept=f.read('catalogue-rows.json').find(r=>r.repo==='org/keep');
  f.refresh('org/new','org/fresh');
  const rows=f.read('catalogue-rows.json');
  expect(rows.find(r=>r.repo==='org/keep')).toEqual(kept);
  for (const repo of ['org/new','org/fresh']) {
    expect(rows.filter(r=>r.repo===repo)).toEqual([{...oldRow(repo),own_files:1,provers:'agda 1',declarations:1,holes:0}]);
  }
  expect(rows.map(r=>r.repo)).toEqual(rows.map(r=>r.repo).sort());
  expect(f.read('unreachable.json')).toEqual([{repo:'org/keep',error:'preserve',exit:7},{repo:'org/down',error:'old',exit:1}]);
});

test('refresh records UTC date and full HEAD, replacing old provenance and retaining others', () => {
  const f=fixture(), before=new Date().toISOString().slice(0,10);
  f.refresh('org/fresh','org/new');
  const records=f.read('refreshed.json');
  expect(records.map(r=>r.repo)).toEqual(['org/fresh','org/keep','org/new']);
  expect(records.find(r=>r.repo==='org/keep')).toEqual(oldRefresh('org/keep'));
  for (const repo of ['org/fresh','org/new']) {
    const record=records.find(r=>r.repo===repo);
    expect(record.commit).toBe(sha);
    expect([before,new Date().toISOString().slice(0,10)]).toContain(record.refreshed);
  }
  const rendered=readFileSync(join(f.root,'docs/catalogue/catalogue.adoc'),'utf8');
  expect(rendered).toContain('== Refreshed since the full census');
  expect(rendered).toContain(`* \`org/fresh\`, ${records[0].refreshed}, commit \`${sha.slice(0,12)}\``);
  expect(rendered).not.toContain(sha);
});

for (const name of ['empty','template']) test(`refresh removes a stale row when ${name==='empty'?'no proof files remain':'only template proof files remain'}`, () => {
  const f=fixture();
  f.refresh(`org/${name}`);
  expect(f.read('catalogue-rows.json').some(r=>r.repo===`org/${name}`)).toBe(false);
  expect(f.read('refreshed.json').find(r=>r.repo===`org/${name}`).commit).toBe(sha);
});

test('unreachable refresh removes stale row and replaces only its failure entry', () => {
  const f=fixture(); f.refresh('org/down');
  expect(f.read('catalogue-rows.json').some(r=>r.repo==='org/down')).toBe(false);
  expect(f.read('unreachable.json')).toEqual([{repo:'org/keep',error:'preserve',exit:7},{repo:'org/fresh',error:'old',exit:1},{repo:'org/down',error:'offline',exit:128}]);
  expect(f.read('refreshed.json').find(r=>r.repo==='org/down').commit).toBe('unreachable');
});

test('first refresh works without a previous provenance file and repeated refresh is idempotent', () => {
  const f=fixture(); rmSync(join(f.census,'refreshed.json'));
  f.refresh('org/fresh');
  const rows=f.read('catalogue-rows.json');
  f.refresh('org/fresh');
  expect(f.read('catalogue-rows.json')).toEqual(rows);
  expect(f.read('refreshed.json')).toHaveLength(1);
  expect(f.read('refreshed.json')[0].commit).toBe(sha);
});

for (const names of [[], ['org/unknown'], ['org/fresh','org/unknown']]) test(`invalid refresh arguments leave committed data untouched: ${JSON.stringify(names)}`, () => {
  const f=fixture();
  const files=['catalogue-rows.json','unreachable.json','refreshed.json'];
  const before=files.map(file=>readFileSync(join(f.census,file),'utf8'));
  const result=f.run('refresh-rows.sh',names);
  expect(result.status).toBe(names.length?1:2);
  expect(result.stderr).toContain(names.length?'is not in repos.json':'usage:');
  expect(files.map(file=>readFileSync(join(f.census,file),'utf8'))).toEqual(before);
  expect(existsSync(join(f.root,'docs/catalogue/catalogue.adoc'))).toBe(false);
});

for (const state of ['absent','empty']) test(`renderer omits refresh section with ${state} provenance`, () => {
  const f=fixture();
  if (state==='absent') rmSync(join(f.census,'refreshed.json')); else f.write('refreshed.json',[]);
  const result=f.run('render-catalogue.sh',[f.census]);
  expect(result.status,result.stderr).toBe(0);
  expect(result.stdout).toContain('== Theory');
  expect(result.stdout).not.toContain('== Refreshed since the full census');
});

test('full census supersedes refresh provenance and removes its rendered section', () => {
  const f=fixture();
  writeFileSync(join(f.root,'list.txt'),'org/fresh\n');
  const result=f.run('run-census.sh',[join(f.root,'list.txt')]);
  expect(result.status,result.stderr).toBe(0);
  expect(existsSync(join(f.census,'refreshed.json'))).toBe(false);
  expect(f.read('catalogue-rows.json').map(r=>r.repo)).toEqual(['org/fresh']);
  expect(readFileSync(join(f.root,'docs/catalogue/catalogue.adoc'),'utf8')).not.toContain('== Refreshed since the full census');
});

test('real scanner persists HEAD even when a successfully cloned repo has no proof files', () => {
  const f=fixture();
  cpSync(new URL('census-repo.sh',source),join(f.scripts,'census-repo.sh'));
  const bin=join(f.root,'bin'); mkdirSync(bin);
  // Only Git is replaced: fail on any unexpected operation to forbid network.
  writeFileSync(join(bin,'git'), `#!/usr/bin/env bash
set -euo pipefail
if [ "$1" = clone ]; then mkdir -p "\u0024{!#}"; exit 0; fi
if [ "$1" = -C ]; then
  case "$3" in
    ls-tree) printf 'README.adoc\\n'; exit 0 ;;
    rev-parse) printf '${sha}\\n'; exit 0 ;;
  esac
fi
exit 99
`, {mode:0o755});
  const data=join(f.root,'raw'); mkdirSync(data);
  const result=spawnSync('bash',[join(f.scripts,'census-repo.sh'),'org/empty'],{
    env:{...process.env,BASH_ENV:'/dev/null',PATH:`${bin}:${process.env.PATH}`,MATHESIS_DATA:data},encoding:'utf8',timeout:5000,
  });
  expect(result.status,result.stderr).toBe(0);
  expect(readFileSync(join(data,'out/org__empty.head'),'utf8')).toBe(sha+'\n');
  expect(existsSync(join(data,'clones/org__empty'))).toBe(false);
});
