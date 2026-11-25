# Flag-only measurement (no edits): do the root-level "faces" of a repo's licence agree?
# Faces read at HEAD working tree, repo root only: LICENSE text, *_chora.deed :license, CITATION.cff, Cargo.toml, package.json,
# mix.exs, guix.scm. A face yields a set of code-licence families; CC-* (prose) is ignored.
ROOT = '/home/user/estate'
FAM = [[/PMPL|PALIMPSEST/i, 'PMPL'], [/AGPL|AFFERO/i, 'AGPL'], [/LGPL|LESSER GENERAL/i, 'LGPL'], [/\bGPL|GNU GENERAL PUBLIC/i, 'GPL'],
       [/MPL|MOZILLA PUBLIC/i, 'MPL'], [/\bMIT\b|EXPAT/i, 'MIT'], [/APACHE|ASL2/i, 'APACHE'], [/\bBSD/i, 'BSD'], [/UNLICEN[SC]E/i, 'UNLICENSE'],
       [/ALL RIGHTS RESERVED|PROPRIETARY/i, 'ARR'], [/\bISC\b/i, 'ISC'], [/EUPL/i, 'EUPL'], [/\b0BSD|CC0/i, 'CC0']]
def fams(s)
  return nil if s.nil?
  t = s.gsub(/PMPL[-A-Za-z0-9.]*/i) { |m| m } # keep
  out = []
  u = t.dup
  if u =~ /PMPL|PALIMPSEST/i then out << 'PMPL'; u = u.gsub(/PMPL[-A-Za-z0-9.]*|PALIMPSEST[-A-Za-z ]*/i, ' ') end
  if u =~ /AGPL|AFFERO/i then out << 'AGPL'; u = u.gsub(/AGPL[-A-Za-z0-9.+]*|GNU AFFERO GENERAL PUBLIC[A-Za-z ]*/i, ' ') end
  if u =~ /LGPL|LESSER GENERAL/i then out << 'LGPL'; u = u.gsub(/LGPL[-A-Za-z0-9.+]*|GNU LESSER GENERAL PUBLIC[A-Za-z ]*/i, ' ') end
  out << 'GPL' if u =~ /\bGPL|GNU GENERAL PUBLIC/i
  out << 'MPL' if u =~ /\bMPL|MOZILLA PUBLIC/i
  out << 'MIT' if u =~ /\bMIT\b|EXPAT/i
  out << 'APACHE' if u =~ /APACHE|ASL2/i
  out << 'BSD' if u =~ /\bBSD/i
  out << 'ARR' if u =~ /ALL RIGHTS RESERVED|PROPRIETARY/i
  out << 'EUPL' if u =~ /EUPL/i
  out.empty? ? nil : out.uniq.sort
end
rows = []
Dir.glob("#{ROOT}/*/*").select { |d| File.directory?(d) }.sort.each do |d|
  repo = d.sub("#{ROOT}/", '')
  f = {}
  lic = %w[LICENSE LICENSE.txt LICENSE.md LICENCE].map { |n| "#{d}/#{n}" }.find { |p| File.file?(p) }
  f['LICENSE'] = fams(File.read(lic, 1500, encoding: 'BINARY')) if lic
  deed = Dir.glob("#{d}/*_chora.deed").first
  if deed
    v = File.read(deed, encoding: 'BINARY').scan(/:licen[sc]e\s+"?([^"\s)]+(?: (?:OR|AND|WITH) [^"\s)]+)*)"?/i).flatten
    f['deed'] = fams(v.join(' ')) unless v.empty?
  end
  { 'CITATION.cff' => /^license:\s*(.+)$/i, 'Cargo.toml' => /^license\s*=\s*"([^"]+)"/, 'package.json' => /"license"\s*:\s*"([^"]+)"/,
    'mix.exs' => /licenses:\s*\[([^\]]+)\]/, 'guix.scm' => /\(license\s+([^\n]+)/ }.each do |n, re|
    p = "#{d}/#{n}"
    next unless File.file?(p)
    v = File.read(p, encoding: 'BINARY').scan(re).flatten
    v = v.map { |x| x.gsub(/license:/, '').gsub(/mpl2\.0/i, 'MPL-2.0').gsub(/agpl3\+?/i, 'AGPL-3.0').gsub(/gpl3\+?/i, 'GPL-3.0').gsub(/expat/i, 'MIT').gsub(/asl2\.0/i, 'Apache-2.0') } if n == 'guix.scm'
    fm = fams(v.join(' '))
    f[n] = fm if fm
  end
  f.reject! { |_, v| v.nil? }
  next if f.size < 2
  sets = f.values.uniq
  rows << [repo, sets.size, f.map { |k, v| "#{k}=#{v.join('+')}" }.join(' ; ')]
end
dis = rows.select { |r| r[1] > 1 }
puts "repos with >=2 readable licence faces: #{rows.size}"
puts "repos whose faces name different code-licence family sets: #{dis.size}"
pat = dis.group_by { |r| r[2].split(' ; ').map { |x| x.split('=') }.group_by { |_, v| v }.map { |v, ks| "#{v}:{#{ks.map(&:first).sort.join(',')}}" }.sort.join(' vs ') }
pat.sort_by { |_, v| -v.size }.first(14).each { |k, v| puts format('%4d  %s   e.g. %s', v.size, k, v.first[0]) }
File.write('/tmp/r5/licence_faces.tsv', rows.map { |r| r.join("\t") }.join("\n") + "\n")
