# Replay of the 2026-06 "add timeout-minutes to all jobs" sweep on the HEAD corpus, two ways (in memory only; nothing written to the clones):
#   PARSED : a function on the parsed document (add timeout-minutes: 10 to every job that lacks it)
#   TEXT   : a line-position writer (insert the line after every 2-space-indented key under `jobs:`)
# Gate g  : closed-key workflow schema (CallJob has no timeout-minutes), payload-indifferent.
# Tests   : (1) free-theorem prediction: g(PARSED(x)) is constant on every L4 shape class;
#           (2) class canaries: how many classes must be excluded, how many files that protects;
#           (3) T1 quotient-respect: does TEXT agree with PARSED after parsing?
require 'yaml'; require 'date'; require 'json'; require 'digest'
ROOT = '/home/user/estate'
TOP = %w[name run-name on true permissions env defaults concurrency jobs]
CALL = %w[name uses with secrets needs if permissions concurrency strategy]
STEPS = %w[name runs-on steps needs if permissions env defaults timeout-minutes strategy continue-on-error container services outputs concurrency environment]
def load(txt)
  d = YAML.safe_load(txt, aliases: true, permitted_classes: [Date, Time, Symbol]) rescue (return nil)
  d.is_a?(Hash) ? d : nil
end
def ok?(d)
  return false unless d && d['jobs'].is_a?(Hash) && (d.key?('on') || d.key?(true)) && (d.keys.map(&:to_s) - TOP).empty?
  d['jobs'].all? do |_, j|
    next false unless j.is_a?(Hash)
    j.key?('uses') ? (j.keys.map(&:to_s) - CALL).empty? : ((j.keys.map(&:to_s) - STEPS).empty? && j['steps'].is_a?(Array) && j.key?('runs-on'))
  end
end
def canon(o)
  case o
  when Hash then o.keys.map(&:to_s).sort.map { |k| [k, canon(o[o.keys.find { |x| x.to_s == k }])] }.to_h
  when Array then o.map { |x| canon(x) }
  else o
  end
end
def dupkeys?(node)
  return false unless node.respond_to?(:children) && node.children
  if node.is_a?(Psych::Nodes::Mapping)
    ks = node.children.each_slice(2).map { |k, _| k.respond_to?(:value) ? k.value : nil }.compact
    return true if ks.uniq.size != ks.size
  end
  node.children.any? { |c| dupkeys?(c) }
end
def parsed_sweep(d)
  e = Marshal.load(Marshal.dump(d))
  e['jobs'].each_value { |j| j['timeout-minutes'] = 10 if j.is_a?(Hash) && !j.key?('timeout-minutes') }
  e
end
def text_sweep(txt)
  out = []; injobs = false
  txt.each_line do |l|
    out << l
    injobs = true if l =~ /\Ajobs:\s*\z/
    injobs = false if l =~ /\A[A-Za-z]/ && l !~ /\Ajobs:/
    out << "    timeout-minutes: 10\n" if injobs && l =~ /\A  [A-Za-z0-9_-]+:\s*\z/
  end
  out.join
end
cls = {}
File.readlines('/tmp/r5/tower.tsv', chomp: true).each { |l| a = l.split("\t"); cls["#{a[0]}/.github/workflows/#{a[1]}"] = a[6] }
t1_dup = 0; valid = 0; broke = 0; byclass = Hash.new { |h, k| h[k] = [] }; t1_bad = 0; t1_dead = 0; t1_tot = 0
cls.each do |rel, c|
  txt = File.read("#{ROOT}/#{rel}", encoding: 'UTF-8') rescue next
  d = load(txt)
  next unless ok?(d)
  valid += 1
  after = parsed_sweep(d)
  v = ok?(after)
  broke += 1 unless v
  byclass[c] << v
  ts = text_sweep(txt); t = load(ts); t1_tot += 1
  if t.nil? then t1_dead += 1
  elsif dupkeys?(YAML.parse(ts)) then t1_dup += 1
  elsif JSON.generate(canon(t)) != JSON.generate(canon(after)) then t1_bad += 1
  end
end
mixed = byclass.count { |_, vs| vs.uniq.size > 1 }
bad_classes = byclass.count { |_, vs| vs.uniq == [false] }
puts "schema-valid files before the sweep: #{valid} in #{byclass.size} L4 shape classes"
puts "PARSED sweep: files made schema-invalid: #{broke}"
puts "free-theorem prediction: classes with a MIXED verdict after the sweep: #{mixed} (prediction: 0)"
puts "classes whose single canary fails: #{bad_classes}; files those classes contain: #{byclass.select { |_, vs| vs.uniq == [false] }.values.sum(&:size)}"
puts "T1 quotient-respect, TEXT vs PARSED on #{t1_tot} valid files: TEXT output unparseable #{t1_dead}; has a duplicate key #{t1_dup}; parses but differs from PARSED #{t1_bad}; agrees #{t1_tot - t1_dead - t1_dup - t1_bad}"
