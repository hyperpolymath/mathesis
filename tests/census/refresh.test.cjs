// SPDX-License-Identifier: MPL-2.0
const {test}=require('node:test');
const assert=require('node:assert/strict');
const fs=require('node:fs');
const os=require('node:os');
const path=require('node:path');
const {spawnSync,spawn}=require('node:child_process');
const root=path.resolve(__dirname,'../..');
const realMv=spawnSync('which',['mv'],{encoding:'utf8'}).stdout.trim();
function fixture(t) {
  const dir=fs.mkdtempSync(path.join(os.tmpdir(),'census-test-'));
  t.after(()=>fs.rmSync(dir,{recursive:true,force:true}));
  const scripts=path.join(dir,'scripts/census');
  fs.mkdirSync(scripts,{recursive:true});
  fs.cpSync(path.join(root,'scripts/census'),scripts,{recursive:true});
  const cat=path.join(dir,'docs/catalogue'), c=path.join(cat,'census');
  fs.mkdirSync(c,{recursive:true});
  const json=(f,v)=>fs.writeFileSync(path.join(c,f+'.json'),JSON.stringify(v));
  json('repos',['a','b','empty','fail','partial','private'].map(n=>({full_name:'owner/'+n,visibility:n==='private'?'private':'public',fork:false})));
  json('catalogue-rows',[]);json('unreachable',[]);
  json('refreshed',[{repo:'owner/empty',refreshed:'old',commit:'old'}]);
  fs.writeFileSync(path.join(c,'template-paths.txt'),'template.lean\n');
  fs.writeFileSync(path.join(cat,'catalogue.adoc'),'old catalogue\n');
  const bin=path.join(dir,'bin');fs.mkdirSync(bin);
  const executable=(name,text)=>fs.writeFileSync(path.join(bin,name),'#!/usr/bin/env bash\nset -eu\n'+text,{mode:0o755});
  executable('sleep','exit 0\n');
  executable('git',`
if [ "$1" = clone ]; then
  repo=\${@: -2:1}; dest=\${@: -1}
  echo "$repo" >> "$TEST_LOG"
  [[ "$repo" != */fail ]] || exit 1
  mkdir -p "$dest"; echo "$repo" > "$dest/repo"
  exit 0
fi
repo=$(cat "$2/repo")
case "$3" in
  ls-tree) [[ "$repo" == */empty ]] || echo proof.lean ;;
  rev-parse) if [[ "$repo" == */partial ]]; then echo HEAD; exit 1; fi; echo 0123456789abcdef0123456789abcdef01234567 ;;
  checkout) echo 'theorem example : True := by trivial' > "$2/proof.lean" ;;
esac
`);
  executable('mv',`
case "\${TEST_MV:-}" in
 fail) exit 1 ;;
 before) kill -KILL "$PPID"; exit 1 ;;
 after) "${realMv}" "$@"; kill -KILL "$PPID"; exit 0 ;;
esac
exec "${realMv}" "$@"
`);
  const env={...process.env,PATH:bin+':'+process.env.PATH,TEST_LOG:path.join(dir,'clones')};
  const run=(args,extra={},script='refresh-rows.sh')=>spawnSync('bash',[path.join(scripts,script),...args],{env:{...env,...extra},encoding:'utf8'});
  const read=f=>JSON.parse(fs.readFileSync(path.join(c,f+'.json'),'utf8'));
  const snapshot=()=>['catalogue.adoc','census/catalogue-rows.json','census/unreachable.json','census/refreshed.json'].map(f=>fs.existsSync(path.join(cat,f))?fs.readFileSync(path.join(cat,f),'utf8'):null);
  return {dir,scripts,cat,c,env,run,read,snapshot};
}
test('validate all requested visibility and membership before any clones',t=>{
  const f=fixture(t),before=f.snapshot();
  for(const n of ['private','missing']) {
    assert.notEqual(f.run(['owner/a','owner/'+n]).status,0);
    assert.equal(fs.existsSync(f.env.TEST_LOG),false);
    assert.deepEqual(f.snapshot(),before);
  }
});
test('deduplicate requests, remove empty rows/provenance, retain successful HEAD',t=>{
  const f=fixture(t),r=f.run(['owner/a','owner/a','owner/empty']);
  assert.equal(r.status,0,r.stderr);
  assert.equal(fs.readFileSync(f.env.TEST_LOG,'utf8').trim().split('\n').length,2);
  assert.deepEqual(f.read('refreshed').map(r=>r.repo),['owner/a']);
  assert.equal(f.read('refreshed')[0].commit,'0123456789abcdef0123456789abcdef01234567');
  assert.deepEqual(f.read('catalogue-rows').map(r=>r.repo),['owner/a']);
  assert.equal(f.run([],{},'check-catalogue.sh').status,0);
});
test('failed rev-parse discards its partial stdout',t=>{
  const f=fixture(t),r=f.run(['owner/partial']);
  assert.equal(r.status,0,r.stderr);
  assert.equal(f.read('refreshed')[0].commit,'old');
  assert.equal(f.read('refreshed')[1].commit,'unavailable');
});
test('both failed clone attempts abort without publication',t=>{
  const f=fixture(t),before=f.snapshot(),r=f.run(['owner/a','owner/fail']);
  assert.notEqual(r.status,0);assert.match(r.stderr,/both clone attempts failed/);
  assert.deepEqual(f.snapshot(),before);
  assert.equal(fs.readFileSync(f.env.TEST_LOG,'utf8').trim().split('\n').filter(r=>r.endsWith('/fail')).length,2);
});
for(const mode of ['fail','before','after']) test('atomic publication: '+mode,t=>{
  const f=fixture(t),before=f.snapshot(),r=f.run(['owner/a'],{TEST_MV:mode});
  assert.ok(r.status!==0);
  if(mode==='after') assert.equal(f.run([],{},'check-catalogue.sh').status,0);
  else assert.deepEqual(f.snapshot(),before);
  // A killed or failed publisher must release the lock.
  const next=f.run(['owner/b']);assert.equal(next.status,0,next.stderr);
  assert.deepEqual(f.read('catalogue-rows').map(r=>r.repo),mode==='after'?['owner/a','owner/b']:['owner/b']);
});
test('overlapping refreshes preserve both merged rows',async t=>{
  const f=fixture(t);
  const start=n=>new Promise((resolve,reject)=>{
    const child=spawn('bash',[path.join(f.scripts,'refresh-rows.sh'),'owner/'+n],{env:f.env,stdio:'ignore'});
    child.on('error',reject);child.on('exit',code=>code===0?resolve():reject(new Error('exit '+code)));
  });
  await Promise.all([start('a'),start('b')]);
  assert.deepEqual(f.read('catalogue-rows').map(r=>r.repo),['owner/a','owner/b']);
  assert.equal(f.run([],{},'check-catalogue.sh').status,0);
});
test('full run preserves provenance on build/install failure and clears it on success',t=>{
  const f=fixture(t),before=f.snapshot(),builder=path.join(f.scripts,'build-rows.sh');
  const original=fs.readFileSync(builder);fs.writeFileSync(builder,'exit 1\n');
  const list=path.join(f.dir,'list');fs.writeFileSync(list,'owner/a\n');
  assert.notEqual(f.run([list],{},'run-census.sh').status,0);
  assert.deepEqual(f.snapshot(),before);fs.writeFileSync(builder,original);
  assert.notEqual(f.run([list],{TEST_MV:'fail'},'run-census.sh').status,0);
  assert.deepEqual(f.snapshot(),before);
  const r=f.run([list],{},'run-census.sh');assert.equal(r.status,0,r.stderr);
  assert.equal(fs.existsSync(path.join(f.c,'refreshed.json')),false);
  assert.equal(f.run([],{},'check-catalogue.sh').status,0);
});
test('invalid staged output or renderer failure never publishes',t=>{
  const f=fixture(t),before=f.snapshot();
  const builder=path.join(f.scripts,'build-rows.sh'),original=fs.readFileSync(builder);
  fs.writeFileSync(builder,"echo '{invalid'\n");
  assert.notEqual(f.run(['owner/a']).status,0);
  assert.deepEqual(f.snapshot(),before);
  fs.writeFileSync(builder,original);
  fs.writeFileSync(path.join(f.scripts,'render-catalogue.sh'),"echo partial; exit 1\n");
  assert.notEqual(f.run(['owner/a']).status,0);
  assert.deepEqual(f.snapshot(),before);
});
test('map excludes substantive finance READMEs and retains title-only stubs',()=>{
  const map=fs.readFileSync(path.join(root,'docs/architecture/REPOSITORY-MAP.adoc'),'utf8');
  for(const p of ['finance','finance/cohort-economics','finance/liquidity']) {
    assert.ok(!map.includes('| `applied-systems/'+p+'/`'));
  }
  assert.ok(map.includes('| `docs/theory/mathematics/`'));
});
