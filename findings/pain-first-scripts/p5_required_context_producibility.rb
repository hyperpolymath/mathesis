#!/usr/bin/env ruby
# SPDX-License-Identifier: MPL-2.0
# Read-only probe (2026-11-24). Pain class: absence / skip / never-started read as pass.
# For every clone with .github/rulesets/*.json: take each required_status_checks context and ask whether a
# job in .github/workflows can produce a check run of exactly that name (job id or job `name:`; a context
# "A / B" is matched on caller job A only, since the callee job lives in another repo). For producible
# contexts, record the ways the producing job can end without running: job-level `if:`, workflow-level
# paths filter, no pull_request trigger. Approximate: matrix-expanded names and expressions in `name:` are
# not expanded, so "no producer found" is an upper bound on phantom contexts.
require 'json'; require 'yaml'
est = ENV['EST'] || '/home/user/estate'
tot = Hash.new(0); rows = []
Dir.glob("#{est}/*/*/.github/rulesets").sort.each do |rs|
  repo = rs.sub("#{est}/", '').sub('/.github/rulesets', '')
  ctxs = []
  Dir.glob("#{rs}/*.json").each do |f|
    j = (JSON.parse(File.read(f)) rescue nil) or next
    (j['rules'] || []).each do |r|
      next unless r.is_a?(Hash) && r['type'] == 'required_status_checks'
      ((r['parameters'] || {})['required_status_checks'] || []).each { |c| ctxs << c['context'] if c.is_a?(Hash) && c['context'].to_s != '' }
    end
  end
  ctxs.uniq!
  next if ctxs.empty?
  tot[:repos_with_required] += 1
  jobs = {}   # name -> [ {file, has_if, paths_filter, on_pr} ]
  Dir.glob("#{est}/#{repo}/.github/workflows/*.{yml,yaml}").each do |wf|
    y = (YAML.safe_load(File.read(wf), aliases: true) rescue nil)
    next unless y.is_a?(Hash) && y['jobs'].is_a?(Hash)
    on = y[true] || y['on']
    on_pr = on.is_a?(Hash) ? (on.key?('pull_request') || on.key?('pull_request_target') || on.key?('merge_group')) : [on].flatten.compact.map(&:to_s).any? { |e| e.start_with?('pull_request') }
    pf = on.is_a?(Hash) && on['pull_request'].is_a?(Hash) && (on['pull_request'].key?('paths') || on['pull_request'].key?('paths-ignore'))
    y['jobs'].each do |id, job|
      next unless job.is_a?(Hash)
      [id.to_s, job['name'].to_s].reject(&:empty?).uniq.each do |nm|
        (jobs[nm] ||= []) << { file: File.basename(wf), has_if: job.key?('if'), paths: pf, on_pr: on_pr }
      end
    end
  end
  ctxs.each do |c|
    tot[:contexts] += 1
    key = c.split(' / ').first
    prod = jobs[c] || jobs[key]
    if prod.nil?
      tot[:no_producer] += 1; rows << [repo, c, 'NO-PRODUCER']
    else
      tot[:producible] += 1
      tot[:producer_has_if] += 1 if prod.all? { |p| p[:has_if] }
      tot[:producer_paths_filtered] += 1 if prod.all? { |p| p[:paths] }
      tot[:producer_not_on_pr] += 1 if prod.none? { |p| p[:on_pr] }
      rows << [repo, c, 'if-skippable'] if prod.all? { |p| p[:has_if] }
      rows << [repo, c, 'paths-filtered'] if prod.all? { |p| p[:paths] }
      rows << [repo, c, 'not-on-pull_request'] if prod.none? { |p| p[:on_pr] }
    end
  end
end
puts "repos with a ruleset naming required status contexts: #{tot[:repos_with_required]}"
puts "required contexts (repo, context) pairs: #{tot[:contexts]}"
puts "  a job of that name exists in the repo's workflows: #{tot[:producible]}"
puts "  no producing job found (phantom candidates, upper bound): #{tot[:no_producer]}"
puts "  producible, but every producer has a job-level if: (can be skipped): #{tot[:producer_has_if]}"
puts "  producible, but every producer is paths-filtered on pull_request: #{tot[:producer_paths_filtered]}"
puts "  producible, but no producer triggers on pull_request/merge_group: #{tot[:producer_not_on_pr]}"
File.write(ENV['OUT'] || '/tmp/pf/p5_rows.tsv', rows.map { |r| r.join("\t") }.join("\n") + "\n")
