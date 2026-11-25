# Resemblance tower over workflow files at HEAD (read-only).
# Levels (each a function of the previous one's representative, so classes are nested):
#   L0 raw bytes
#   L2 parsed YAML, canonical JSON (keys sorted)
#   L3 L2 with every `uses:` ref abstracted to @PIN
#   L4 "shape + inspected leaves": scalars -> type tag, EXCEPT mapping keys and the action/workflow
#      path of `uses:` (ref dropped); sequence lengths kept
#   L5 skeleton: L4 with sequences collapsed to the sorted set of distinct element shapes
# Side level (NOT in the chain): L1 text with full-line comments and blank lines stripped.
require 'yaml'
require 'json'
require 'digest'
require 'date'

ROOT = '/home/user/estate'
files = Dir.glob("#{ROOT}/*/*/.github/workflows/*.{yml,yaml}").sort

def canon(o)
  case o
  when Hash then o.keys.map(&:to_s).sort.map { |k| [k, canon(o[o.keys.find { |x| x.to_s == k }])] }.to_h
  when Array then o.map { |x| canon(x) }
  else o
  end
end

def abstract_pins(o, key = nil)
  case o
  when Hash then o.map { |k, v| [k, abstract_pins(v, k)] }.to_h
  when Array then o.map { |x| abstract_pins(x, key) }
  when String then key == 'uses' ? o.sub(/@.*\z/, '@PIN') : o
  else o
  end
end

def tag(v)
  case v
  when String then 's'
  when Integer, Float then 'n'
  when true, false then 'b'
  when nil then '0'
  else 'x'
  end
end

def shape(o, key = nil)
  case o
  when Hash then o.map { |k, v| [k, shape(v, k)] }.to_h
  when Array then o.map { |x| shape(x, key) }
  when String then key == 'uses' ? o : tag(o)
  else tag(o)
  end
end

def skeleton(o)
  case o
  when Hash then o.map { |k, v| [k, skeleton(v)] }.to_h
  when Array then o.map { |x| JSON.generate(skeleton(x)) }.uniq.sort
  else o
  end
end

rows = []
files.each do |f|
  raw = File.binread(f)
  name = File.basename(f)
  repo = f.sub("#{ROOT}/", '').split('/')[0, 2].join('/')
  l0 = Digest::SHA256.hexdigest(raw)[0, 16]
  l1 = Digest::SHA256.hexdigest(raw.force_encoding('BINARY').lines.reject { |l| l =~ /\A\s*#/ || l =~ /\A\s*\z/ }.map(&:rstrip).join("\n"))[0, 16]
  begin
    doc = YAML.safe_load(raw.force_encoding('UTF-8'), aliases: true, permitted_classes: [Date, Time, Symbol])
    raise 'not a mapping' unless doc.is_a?(Hash)
    c = canon(doc)
    l2 = Digest::SHA256.hexdigest(JSON.generate(c))[0, 16]
    p3 = abstract_pins(c)
    l3 = Digest::SHA256.hexdigest(JSON.generate(p3))[0, 16]
    s4 = shape(p3)
    l4 = Digest::SHA256.hexdigest(JSON.generate(s4))[0, 16]
    l5 = Digest::SHA256.hexdigest(JSON.generate(skeleton(s4)))[0, 16]
    jobs = c['jobs'].is_a?(Hash) ? c['jobs'] : {}
    call = jobs.values.count { |j| j.is_a?(Hash) && j.key?('uses') }
    steps = jobs.values.count { |j| j.is_a?(Hash) && j.key?('steps') }
    rows << [repo, name, l0, l1, l2, l3, l4, l5, call, steps].join("\t")
  rescue StandardError, Psych::Exception => e
    rows << [repo, name, l0, l1, "DEAD:#{l0}", "DEAD:#{l0}", "DEAD:#{l0}", "DEAD:#{l0}", -1, -1].join("\t")
  end
end
File.write('/tmp/r5/tower.tsv', rows.join("\n") + "\n")
puts "files #{rows.size}"
