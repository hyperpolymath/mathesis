#!/usr/bin/env ruby
# Read-only: applies three layers to a blob and prints which layer rejects it.
#  L1 parse (Psych), L2 duplicate mapping key, L3 closed sum-type schema (same key sets as pain-first p2, scopes = GitHub docs list fetched 2026-11-24 + p2's)
require 'yaml'; require 'psych'
COMMON = %w[name needs if permissions concurrency strategy secrets]
STEPS = COMMON + %w[runs-on environment outputs env defaults steps timeout-minutes continue-on-error container services] - %w[secrets]
CALL  = COMMON + %w[uses with]
STEP  = %w[id if name uses run shell with env continue-on-error timeout-minutes working-directory]
WF   = %w[name run-name on permissions env defaults concurrency jobs]
SCOPES = %w[actions artifact-metadata attestations checks code-quality contents copilot-requests deployments discussions id-token issues models packages pages pull-requests repository-projects security-events statuses vulnerability-alerts]
def dups(node, path, out)
  case node
  when Psych::Nodes::Mapping
    seen = {}
    node.children.each_slice(2) do |k, v|
      key = k.respond_to?(:value) ? k.value : k.to_s
      out << "#{path}/#{key}" if seen[key]; seen[key] = true
      dups(v, "#{path}/#{key}", out)
    end
  when Psych::Nodes::Sequence then node.children.each_with_index { |c, i| dups(c, "#{path}[#{i}]", out) }
  when Psych::Nodes::Document, Psych::Nodes::Stream then node.children.each { |c| dups(c, path, out) }
  end
end
def perms(p, where, bad)
  return if p.nil?
  if p.is_a?(String) then bad << "#{where}: permissions scalar '#{p}'" unless %w[read-all write-all].include?(p)
  elsif p.is_a?(Hash) then p.each { |k, v| bad << "#{where}: permission scope '#{k}'" unless SCOPES.include?(k.to_s); bad << "#{where}: permission value '#{v}'" unless %w[read write none].include?(v.to_s) }
  else bad << "#{where}: permissions not scalar/mapping" end
end
def verdict(src)
  src = src.dup.force_encoding('UTF-8')
  begin
    ast = Psych.parse_stream(src); d = []; dups(ast, '', d)
    y = YAML.safe_load(src, aliases: true)
  rescue Psych::Exception, ArgumentError => e
    return ['L1-parse', e.message[0,90]]
  end
  return ['L2-dup', d.first(2).join(',')] unless d.empty?
  return ['L3-schema', 'top level not a mapping'] unless y.is_a?(Hash)
  bad = []
  y = y.transform_keys { |k| k == true ? 'on' : k.to_s }
  (y.keys - WF).each { |k| bad << "workflow key '#{k}'" }
  bad << 'no on:' unless y.key?('on'); perms(y['permissions'], 'workflow', bad)
  jobs = y['jobs']
  if !jobs.is_a?(Hash) || jobs.empty? then bad << 'no jobs'
  else jobs.each do |id, j|
    unless j.is_a?(Hash) then bad << "job #{id}: not a mapping"; next end
    ks = j.keys.map(&:to_s); perms(j['permissions'], "job", bad)
    if ks.include?('uses') && !ks.include?('steps') && !ks.include?('runs-on') then (ks - CALL).each { |k| bad << "CallJob key '#{k}'" }
    elsif ks.include?('steps') && ks.include?('runs-on') && !ks.include?('uses')
      (ks - STEPS).each { |k| bad << "StepsJob key '#{k}'" }
      (j['steps'].is_a?(Array) ? j['steps'] : []).each do |s|
        unless s.is_a?(Hash) then bad << 'step: not a mapping'; next end
        sk = s.keys.map(&:to_s); bad << 'step: needs exactly one of run/uses' unless (sk.include?('run') ^ sk.include?('uses'))
        (sk - STEP).each { |k| bad << "step key '#{k}'" }
        bad << 'step: with: on a run step' if sk.include?('run') && sk.include?('with')
      end
    else bad << "job #{id} inhabits neither StepsJob nor CallJob" end
  end end
  bad.empty? ? ['PASS',''] : ['L3-schema', bad.uniq.first(2).join('; ')]
end
if __FILE__ == $0
  tab = Hash.new { |h,k| h[k] = Hash.new(0) }
  File.readlines('/tmp/wfv/index.tsv', chomp: true).each do |l|
    wave, repo, h, date, f, id = l.split("\t")
    pre = verdict(File.read("/tmp/wfv/blobs/#{id}.pre")); post = verdict(File.read("/tmp/wfv/blobs/#{id}.post"))
    tab[wave]["pre:#{pre[0]}"] += 1; tab[wave]["post:#{post[0]}"] += 1; tab[wave][:n] += 1
    puts [wave, repo, h[0,8], File.basename(f), "PRE=#{pre[0]}", pre[1], "POST=#{post[0]}", post[1]].join("\t") if ENV['V']
  end
  tab.sort.each { |w, c| puts "#{w}\tn=#{c[:n]}\t" + c.reject{|k,_| k==:n}.sort_by{|k,_| k.to_s}.map{|k,v| "#{k}=#{v}"}.join("  ") }
end
