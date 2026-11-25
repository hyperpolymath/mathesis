# Probe: radius-1 "layout-only" repairs of live parse-dead / schema-dead workflows (read-only; works on in-memory copies).
# Valid = parses to a mapping with jobs, every job is exactly a StepsJob or a CallJob (call job has no steps/runs-on/timeout-minutes),
#         no duplicate mapping keys.
require 'yaml'; require 'date'; require 'json'
ROOT='/home/user/estate/hyperpolymath'
TOP = %w[name run-name on true permissions env defaults concurrency jobs]
CALL = %w[name uses with secrets needs if permissions concurrency strategy]
STEPS = %w[name runs-on steps needs if permissions env defaults timeout-minutes strategy continue-on-error container services outputs concurrency environment]
SCOPES = %w[actions attestations checks contents deployments discussions id-token issues models packages pages pull-requests repository-projects security-events statuses]
def perms_ok?(p) = p.nil? || %w[read-all write-all].include?(p) || (p.is_a?(Hash) && p.all? { |k, v| SCOPES.include?(k.to_s) && %w[read write none].include?(v.to_s) })
def dupkeys?(node)
  return false unless node.respond_to?(:children) && node.children
  if node.is_a?(Psych::Nodes::Mapping)
    ks = node.children.each_slice(2).map { |k,_| k.respond_to?(:value) ? k.value : nil }.compact
    return true if ks.uniq.size != ks.size
  end
  node.children.any? { |c| dupkeys?(c) }
end
def valid?(txt)
  ast = YAML.parse(txt) rescue (return false)
  return false if ast.nil? || dupkeys?(ast)
  d = YAML.safe_load(txt, aliases: true, permitted_classes: [Date,Time,Symbol]) rescue (return false)
  return false unless d.is_a?(Hash) && d['jobs'].is_a?(Hash) && (d.key?('on') || d.key?(true))
  return false unless (d.keys.map(&:to_s) - TOP).empty? && perms_ok?(d['permissions'])
  d['jobs'].all? do |_, j|
    next false unless j.is_a?(Hash)
    next false unless perms_ok?(j['permissions'])
    if j.key?('uses') then (j.keys.map(&:to_s) - CALL).empty? else (j.keys.map(&:to_s) - STEPS).empty? && j['steps'].is_a?(Array) && j.key?('runs-on') end
  end
end
def nf(txt) = JSON.generate(YAML.safe_load(txt, aliases: true, permitted_classes: [Date,Time,Symbol]))
def probe(label, path, lines_idx)
  src = File.read(path, encoding: 'UTF-8').lines
  puts "== #{label}: valid as committed? #{valid?(src.join)}"
  ok = {}
  (0..16).each do |k|
    t = src.dup
    lines_idx.each { |i| t[i] = (' ' * k) + t[i].lstrip }
    ok[k] = nf(t.join) if valid?(t.join)
  end
  puts "   re-indent line(s) #{lines_idx.map { |i| i + 1 }.inspect} to k spaces: valid for k in #{ok.keys.inspect}; distinct normal forms among valid: #{ok.values.uniq.size}"
  t = src.dup; lines_idx.sort.reverse.each { |i| t.delete_at(i) }
  puts "   delete the line(s) instead: valid? #{valid?(t.join)} (content-losing alternative)"
end
probe('cloudguard-server dogfood-gate.yml L398', "#{ROOT}/cloudguard-server/.github/workflows/dogfood-gate.yml", [397])
probe('rrecord-verity dogfood-gate.yml L305', "#{ROOT}/rrecord-verity/.github/workflows/dogfood-gate.yml", [304])
probe('bgp-backbone-lab scorecard.yml L20-22', "#{ROOT}/bgp-backbone-lab/.github/workflows/scorecard.yml", [19,20,21])
# call job + timeout-minutes: delete-one-key repairs
%w[kitchenspeak/.github/workflows/mirror.yml kitchenspeak/.github/workflows/rust-ci.yml kitchenspeak/.github/workflows/scorecard.yml lucidscript/.github/workflows/governance.yml veridical-simulation-core/.github/workflows/spark-theatre-gate.yml].each do |rel|
  src = File.read("#{ROOT}/#{rel}", encoding: 'UTF-8').lines
  cands = src.each_index.select { |i| src[i] =~ /\A\s+[A-Za-z-]+:/ }
  good = cands.select { |i| t = src.dup; t.delete_at(i); valid?(t.join) }
  puts "== #{rel}: valid as committed? #{valid?(src.join)}; single-line deletions that make it valid: #{good.map { |i| src[i].strip }.inspect}"
end
