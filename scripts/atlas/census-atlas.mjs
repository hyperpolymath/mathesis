// SPDX-License-Identifier: MPL-2.0
// A read-only discovery layer over the existing census. No proof-verification claims.
import {readFile, writeFile, mkdir} from 'node:fs/promises';
import {fileURLToPath} from 'node:url';
import {spawnSync} from 'node:child_process';
import path from 'node:path';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const rowsFile=path.join(root,'docs/catalogue/census/catalogue-rows.json');
const output=path.join(root,'docs/atlas/generated');
const validClass=new Set(['theory','engineering']);
const clean=s=>String(s).replaceAll('|','\\|').replaceAll('\n',' ');
const order=(a,b)=>a.localeCompare(b,'en',{sensitivity:'base'});
export function validate(rows){
  if(!Array.isArray(rows))throw Error('Census rows must be an array');
  const seen=new Set();
  for(const r of rows){
    if(typeof r.repo!=='string'||!/^[-\w.]+\/[-\w.]+$/.test(r.repo)||seen.has(r.repo))throw Error('Invalid or duplicate repo');
    if(!validClass.has(r.class))throw Error('Unknown census class '+r.repo);
    if(!Number.isSafeInteger(r.own_files)||r.own_files<0||!Number.isSafeInteger(r.declarations)||r.declarations<0)throw Error('Invalid census counts '+r.repo);
    seen.add(r.repo);
  }
  return rows;
}
export function validateVisibility(rows,repos){
  if(!Array.isArray(repos))throw Error('Census repository inventory missing');
  const visibility=new Map(repos.map(r=>[r.full_name,r.visibility]));
  for(const r of rows)if(visibility.get(r.repo)!=='public')throw Error(`Nonpublic or unlisted census source: ${r.repo}`);
  return rows;
}
export function find(rows,query){
  const terms=query.toLocaleLowerCase('en').trim().split(/\s+/).filter(Boolean);
  return [...rows].filter(r=>terms.every(t=>[r.repo,r.class,r.provers,r.status_doc].some(x=>String(x??'').toLocaleLowerCase('en').includes(t)))).sort((a,b)=>order(a.repo,b.repo));
}
export function pack(rows,query,limit=5000){
  const result=[];
  for(const r of find(rows,query)){
    const next=[...result,{repository:r.repo,census_class:r.class,prover_counts:r.provers,own_proof_files:r.own_files,declaration_count:r.declarations,reported_holes:r.holes,reported_axioms:r.axioms}];
    if(JSON.stringify(next).length>limit)break;
    result.push(next.at(-1));
  }
  return {schema:'mathesis.census-context/0.1',query,results:result,caveat:'Census snapshot only. Counts and declaration detection are not mathematical proof verification. No file-level pointers are present.'};
}
export function render(rows){
  const ordered=[...rows].sort((a,b)=>order(a.repo,b.repo));
  const header='// SPDX-License-Identifier: CC-BY-SA-4.0\n// GENERATED from census/catalogue-rows.json; do not hand-edit.\n';
  const line=r=>`* \u0060${clean(r.repo)}\u0060 — ${clean(r.class)}; ${r.own_files} own proof files, ${r.declarations} detected declarations; provers: ${clean(r.provers)}`;
  const alphabet=[...new Set(ordered.map(r=>r.repo.split('/')[1][0].toLocaleUpperCase('en')))].sort(order);
  const az=header+'= A–Z proof-source directory\n\n'+alphabet.map(letter=>`== ${letter}\n\n${ordered.filter(r=>r.repo.split('/')[1][0].toLocaleUpperCase('en')===letter).map(line).join('\n')}\n`).join('\n');
  const classes=header+'= Census classifications\n\n'+[...validClass].map(c=>`== ${c}\n\n${ordered.filter(r=>r.class===c).map(line).join('\n')}\n`).join('\n');
  const owners=[...new Set(ordered.map(r=>r.repo.split('/')[0]))].sort(order);
  const estates=header+'= Estate organisation view\n\n'+owners.map(owner=>`== ${owner}\n\n${ordered.filter(r=>r.repo.startsWith(owner+'/')).map(line).join('\n')}\n`).join('\n');
  const payload=JSON.stringify({schema:'mathesis.census-atlas/0.1',source:'docs/catalogue/census/catalogue-rows.json',verification:'not_asserted',count:ordered.length,records:ordered});
  const result=spawnSync(process.execPath,[path.join(root,'scripts/ijson-jcs-cli.js'),'canon'],{input:payload,encoding:'utf8'});
  if(result.status!==0)throw Error('JCS canonicalisation failed: '+(result.stderr||''));
  const index=result.stdout+'\n';
  return {'az.adoc':az,'classes.adoc':classes,'organisations.adoc':estates,'index.json':index};
}
async function main(){const [cmd,...args]=process.argv.slice(2);const rows=validate(JSON.parse(await readFile(rowsFile,'utf8')));validateVisibility(rows,JSON.parse(await readFile(path.join(root,'docs/catalogue/census/repos.json'),'utf8')));const views=render(rows);
  if(cmd==='build'){await mkdir(output,{recursive:true});for(const [n,v] of Object.entries(views))await writeFile(path.join(output,n),v);console.log(`Built ${rows.length} census source records`);return;}
  if(cmd==='check'){for(const [n,v] of Object.entries(views)){if(await readFile(path.join(output,n),'utf8')!==v)throw Error(`${n} is stale; run atlas-build`);}console.log('PASS: generated atlas matches census');return;}
  if(cmd==='find'){console.log(JSON.stringify(find(rows,args.join(' ')),null,2));return;}
  if(cmd==='context'){const lim=Number.parseInt(process.env.MATHESIS_CONTEXT_CHARS??'5000',10);if(!Number.isSafeInteger(lim)||lim<100)throw Error('Invalid context limit');console.log(JSON.stringify(pack(rows,args.join(' '),lim),null,2));return;}
  throw Error('Usage: bun scripts/atlas/census-atlas.mjs build|check|find <query>|context <query>');
}
if(process.argv[1]&&path.resolve(process.argv[1])===fileURLToPath(import.meta.url))main().catch(e=>{console.error(e.message);process.exitCode=1;});
