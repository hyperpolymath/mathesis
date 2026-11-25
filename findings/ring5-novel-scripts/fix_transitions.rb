# For a seeded sample of fix-worded commits that touch one workflow file: evaluate offline-decidable gates on the
# parent blob and on the commit blob, and classify the transition. Read-only (git cat-file on two blobs per commit).
require 'yaml'; require 'date'; require 'json'; require 'open3'
ROOT = '/home/user/estate'; STD = "#{ROOT}/metadatastician/standards"
TOP = %w[name run-name on true permissions env defaults concurrency jobs]
CALL = %w[name uses with secrets needs if permissions concurrency strategy]
STEPS = %w[name runs-on steps needs if permissions env defaults timeout-minutes strategy continue-on-error container services outputs concurrency environment]
def dupkeys?(node)
  return false unless node.respond_to?(:children) && node.children
  if node.is_a?(Psych::Nodes::Mapping)
    ks = node.children.each_slice(2).map { |k, _| k.respond_to?(:value) ? k.value : nil }.compact
    return true if ks.uniq.size != ks.size
  end
  node.children.any? { |c| dupkeys?(c) }
end
def load(txt)
  ast = YAML.parse(txt) rescue (return nil)
  return nil if ast.nil? || dupkeys?(ast)
  d = YAML.safe_load(txt, aliases: true, permitted_classes: [Date, Time, Symbol]) rescue (return nil)
  d.is_a?(Hash) ? d : nil
end
def schema_ok?(d)
  return false unless d && d['jobs'].is_a?(Hash) && (d.key?('on') || d.key?(true)) && (d.keys.map(&:to_s) - TOP).empty?
  d['jobs'].all? do |_, j|
    next false unless j.is_a?(Hash)
    j.key?('uses') ? (j.keys.map(&:to_s) - CALL).empty? : ((j.keys.map(&:to_s) - STEPS).empty? && j['steps'].is_a?(Array) && j.key?('runs-on'))
  end
end
def uses(o, acc = [])
  case o
  when Hash then o.each { |k, v| k.to_s == 'uses' && v.is_a?(String) ? acc << v : uses(v, acc) }
  when Array then o.each { |x| uses(x, acc) }
  end
  acc
end
$res = {}
def std_resolves?(sha)
  $res.fetch(sha) { $res[sha] = system('git', '-C', STD, 'cat-file', '-e', "#{sha}^{commit}", out: File::NULL, err: File::NULL) }
end
def gates(txt)
  return { parse: nil, schema: nil, pins: nil, std: nil } if txt.nil?   # file absent
  d = load(txt.force_encoding('UTF-8'))
  g = { parse: !d.nil?, schema: schema_ok?(d) }
  if d
    us = uses(d).reject { |u| u.start_with?('./') || u.start_with?('docker:') }
    g[:pins] = us.all? { |u| u =~ /@[0-9a-f]{40}\z/ }
    st = us.map { |u| u[/\A(?:hyperpolymath|metadatastician)\/standards\/.*@([0-9a-f]{40})\z/, 1] }.compact
    g[:std] = st.empty? ? :na : st.all? { |s| std_resolves?(s) }
  else
    g[:pins] = false; g[:std] = false
  end
  g
end
def blob(repo, rev, path)
  out, st = Open3.capture2e('git', '-C', "#{ROOT}/#{repo}", 'cat-file', '-p', "#{rev}:#{path}")
  st.success? ? out : nil
end
rows = []
File.readlines('/tmp/r5/fix_sample.tsv', chomp: true, encoding: 'UTF-8').each do |l|
  repo, h, d, path, subj = l.split("\t")
  pre = blob(repo, "#{h}^", path); post = blob(repo, h, path)
  a = gates(pre); b = gates(post)
  tr = %i[parse schema pins std].map do |k|
    x, y = a[k], b[k]
    next 'new' if x.nil? && !y.nil?
    next 'gone' if y.nil?
    next 'na' if x == :na || y == :na
    "#{x ? 'P' : 'F'}#{y ? 'P' : 'F'}"
  end
  rows << [repo, h[0, 9], d, File.basename(path), *tr, subj].join("\t")
end
File.write('/tmp/r5/fix_transitions.tsv', rows.join("\n") + "\n")
n = rows.size
t = rows.map { |r| r.split("\t")[4, 4] }
puts "sampled fix-worded single-workflow commits (distinct subjects): #{n}"
%w[parse schema pins std].each_with_index { |g, i| puts format('  %-6s %s', g, t.map { |x| x[i] }.tally.sort.map { |k, v| "#{k}=#{v}" }.join('  ')) }
any_fix = t.count { |x| x.include?('FP') }; any_break = t.count { |x| x.include?('PF') }
still = t.count { |x| x.include?('FF') && !x.include?('FP') }
none = t.count { |x| (x & %w[FP PF FF]).empty? }
puts "commits with at least one decidable fail->pass: #{any_fix}"
puts "commits with at least one decidable pass->fail (a 'fix' that breaks a gate): #{any_break}"
puts "commits that leave a decidable gate failing and repair none: #{still}"
puts "commits with no decidable transition and nothing failing (fix not observable offline): #{none}"
