#!/usr/bin/env ruby
# SPDX-License-Identifier: MPL-2.0
# Read-only probe (2026-11-24). Pain class: workflow config that only the platform parses.
# Reads every top-level .github/workflows/*.yml|yaml with a duplicate-key-detecting YAML walk and checks it
# against a CLOSED schema written as a sum type:
#   Workflow = {name?, run-name?, on, permissions?, env?, defaults?, concurrency?, jobs}
#   Job      = StepsJob {runs-on, steps, ...} | CallJob {uses, with?, secrets?, ...}   (disjoint key sets)
#   Step     = RunStep {run, ...} | UsesStep {uses, with?, ...}                        (exactly one of run/uses)
#   Permissions = read-all | write-all | {} | {scope => read|write|none} with scope from a closed enum
# It reports how many files inhabit the type (so a typed generator could print them) and what the type rejects.
# The key sets are from GitHub's documented workflow syntax as I know it (not fetched here); an unknown key is
# reported as "outside the schema", which is either a defect or a gap in this probe's enum.
require 'yaml'; require 'psych'
est = ENV['EST'] || '/home/user/estate'
WF   = %w[name run-name on permissions env defaults concurrency jobs]
COMMON = %w[name needs if permissions concurrency strategy secrets]
STEPS = COMMON + %w[runs-on environment outputs env defaults steps timeout-minutes continue-on-error container services] - %w[secrets]
CALL  = COMMON + %w[uses with]
STEP  = %w[id if name uses run shell with env continue-on-error timeout-minutes working-directory]
SCOPES = %w[actions attestations checks contents deployments discussions id-token issues models packages pages pull-requests repository-projects security-events statuses vulnerability-alerts]
# vulnerability-alerts: not in the list I knew; 31 callers use it on purpose (comment at Cytoville hypatia-scan.yml:51), so it is admitted here. Not verified against GitHub.

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
files = Dir.glob("#{est}/*/*/.github/workflows/*.{yml,yaml}").sort
tot = Hash.new(0); kinds = Hash.new(0); ex = Hash.new { |h, k| h[k] = [] }
files.each do |f|
  tot[:files] += 1; bad = []; rel = f.sub("#{est}/", '')
  src = File.read(f, mode: 'rb').force_encoding('UTF-8')
  begin
    ast = Psych.parse_stream(src); d = []; dups(ast, '', d); d.each { |x| bad << "duplicate key #{x}" }
    y = YAML.safe_load(src, aliases: true)
  rescue Psych::Exception, ArgumentError => e
    tot[:parse_fail] += 1; kinds['does not parse'] += 1; ex['does not parse'] << rel; next
  end
  unless y.is_a?(Hash) then tot[:not_mapping] += 1; kinds['top level is not a mapping'] += 1; ex['top level is not a mapping'] << rel; next end
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
    else bad << "job inhabits neither StepsJob nor CallJob" end
  end end
  if bad.empty? then tot[:inhabits] += 1 else tot[:rejected] += 1; bad.map { |b| b.sub(/'[^']*'/) { |m| m } }.uniq.each { |b| g = b.sub(/duplicate key .*/, 'duplicate key'); kinds[g] += 1; ex[g] << rel if ex[g].size < 3 } end
end
puts "workflow files: #{tot[:files]}"
puts "  inhabit the closed sum-type schema: #{tot[:inhabits]}"
puts "  rejected by the schema (parse OK): #{tot[:rejected]}"
puts "  do not parse: #{tot[:parse_fail]}; top level not a mapping: #{tot[:not_mapping]}"
puts "-- rejection kinds (files; one file can carry several)"
kinds.sort_by { |_, v| -v }.first(30).each { |k, v| puts format('%6d  %s   e.g. %s', v, k, ex[k].first) }
