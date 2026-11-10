// SPDX-License-Identifier: MPL-2.0
import {test,expect} from 'bun:test';
import {readFileSync} from 'node:fs';
import {validate,validateVisibility,find,pack,render,parseJsonl} from '../../scripts/atlas/census-atlas.mjs';
const rows=parseJsonl(readFileSync(new URL('../../docs/catalogue/census/catalogue-rows.jsonl',import.meta.url),'utf8'));
test('existing corpus validated without modifying provenance',()=>{expect(validate(rows)).toHaveLength(rows.length);expect(rows.some(r=>r.repo==='catachresis-colloquium/IDApTIK')).toBe(true);});
test('duplicate source identity is rejected',()=>{expect(()=>validate([...rows,rows[0]])).toThrow(/duplicate/);});
test('invalid class and counts are rejected',()=>{expect(()=>validate([{...rows[0],class:'machine-verified'}])).toThrow(/class/);expect(()=>validate([{...rows[0],own_files:-1}])).toThrow(/counts/);});
test('case-insensitive source discovery',()=>{const a=find(rows,'IDRIS2');expect(a.length).toBeGreaterThan(0);expect(a.every(r=>r.provers.toLowerCase().includes('idris2'))).toBe(true);});
test('context is bounded and contains verification caveat',()=>{const x=pack(rows,'idris2',500);expect(JSON.stringify(x,null,2).length+1).toBeLessThanOrEqual(500);expect(x.caveat).toContain('not mathematical proof verification');});
test('deterministic A-Z and organisation views',()=>{const a=render(rows),b=render([...rows].reverse());expect(a).toEqual(b);expect(a['az.adoc']).toContain('A–Z proof-source directory');expect(JSON.parse(a['index.json']).verification).toBe('not_asserted');});

test('nonpublic and unknown census sources fail closed',()=>{const inventory=parseJsonl(readFileSync(new URL('../../docs/catalogue/census/repos.jsonl',import.meta.url),'utf8'));expect(validateVisibility(rows,inventory)).toHaveLength(rows.length);expect(()=>validateVisibility(rows,[...inventory.filter(r=>r.full_name!==rows[0].repo)])).toThrow(/Nonpublic or unlisted/);});

test('every census counter is validated',()=>{for(const k of ['holes','axioms','fixture_files','unsafe','policy','own_files','declarations']){expect(()=>validate([{...rows[0],[k]:-1}])).toThrow(/Invalid census counts/);expect(()=>validate([{...rows[0],[k]:'12'}])).toThrow(/Invalid census counts/);}});
test('A-Z display sorts by repository component, not owner',()=>{const v=render([{...rows[0],repo:'z-owner/beta'},{...rows[1],repo:'a-owner/alpha'}]);expect(v['az.adoc'].indexOf('a-owner/alpha')).toBeLessThan(v['az.adoc'].indexOf('z-owner/beta'));});
test('full context budget cannot omit mandatory caveat',()=>{expect(()=>pack(rows,'idris2',100)).toThrow(/budget too small/);expect(JSON.stringify(pack(rows,'idris2',5000),null,2).length+1).toBeLessThanOrEqual(5000);});
test('JSON Lines input: one record per line, LF at the end, no blank line',()=>{expect(parseJsonl('')).toEqual([]);expect(parseJsonl('{"a":1}\n{"a":2}\n')).toEqual([{a:1},{a:2}]);expect(()=>parseJsonl('{"a":1}')).toThrow(/no LF/);expect(()=>parseJsonl('{"a":1}\n\n{"a":2}\n')).toThrow(/blank/);expect(()=>parseJsonl('[{"a":1},\n')).toThrow();});
test('each row names its source commit and census time',()=>{for(const r of rows){expect(r.commit).toMatch(/^[0-9a-f]{40}$/);expect(r.censused_at).toMatch(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$/);}const {commit,censused_at,...bare}=rows[0];expect(()=>validate([bare])).toThrow(/source commit/);expect(()=>validate([{...rows[0],commit:'HEAD'}])).toThrow(/source commit/);expect(()=>validate([{...rows[0],censused_at:'2026-11-10'}])).toThrow(/census time/);});
