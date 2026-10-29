// SPDX-License-Identifier: MPL-2.0
import {test,expect} from 'bun:test';
import {readFileSync} from 'node:fs';
import {validate,validateVisibility,find,pack,render} from '../../scripts/atlas/census-atlas.mjs';
const rows=JSON.parse(readFileSync(new URL('../../docs/catalogue/census/catalogue-rows.json',import.meta.url),'utf8'));
test('existing corpus validated without modifying provenance',()=>{expect(validate(rows)).toHaveLength(239);expect(rows.some(r=>r.repo==='catachresis-colloquium/IDApTIK')).toBe(true);});
test('duplicate source identity is rejected',()=>{expect(()=>validate([...rows,rows[0]])).toThrow(/duplicate/);});
test('invalid class and counts are rejected',()=>{expect(()=>validate([{...rows[0],class:'machine-verified'}])).toThrow(/class/);expect(()=>validate([{...rows[0],own_files:-1}])).toThrow(/counts/);});
test('case-insensitive source discovery',()=>{const a=find(rows,'IDRIS2');expect(a.length).toBeGreaterThan(0);expect(a.every(r=>r.provers.toLowerCase().includes('idris2'))).toBe(true);});
test('context is bounded and contains verification caveat',()=>{const x=pack(rows,'idris2',500);expect(JSON.stringify(x.results).length).toBeLessThanOrEqual(500);expect(x.caveat).toContain('not mathematical proof verification');});
test('deterministic A-Z and organisation views',()=>{const a=render(rows),b=render([...rows].reverse());expect(a).toEqual(b);expect(a['az.adoc']).toContain('A–Z proof-source directory');expect(JSON.parse(a['index.json']).verification).toBe('not_asserted');});

test('nonpublic and unknown census sources fail closed',()=>{const inventory=JSON.parse(readFileSync(new URL('../../docs/catalogue/census/repos.json',import.meta.url),'utf8'));expect(validateVisibility(rows,inventory)).toHaveLength(239);expect(()=>validateVisibility(rows,[...inventory.filter(r=>r.full_name!==rows[0].repo)])).toThrow(/Nonpublic or unlisted/);});
