#!/usr/bin/env ruby
# SPDX-License-Identifier: MPL-2.0
# Read-only probe (2026-11-24). Pain class: absence / skip / never-started read as pass.
# The interim CI gate's shipped profiles (proven-cicd-and-workflows profiles/ci-gate/<owner>/<repo>.json) list
# the REQUIRED identities {job, workflow} per repo. For each identity, at the target repo's checked-out HEAD:
# does the workflow file exist, and does it hold a job whose check-run name is the required one (job id or
# job `name:`; for "A / B" only the caller job A is matched, the callee lives in another repo)? Is that job
# skippable by a job-level `if:`? An identity with no producer is a required check that can never report:
# the gate's rule c turns that into failure ("never reported"), which is the fail-closed side of the same fact.
# Matrix-expanded and expression-valued names are not expanded (so "no producer" is an upper bound).
require 'json'; require 'yaml'
est = ENV['EST'] || '/home/user/estate'
tot = Hash.new(0); rows = []
Dir.glob("#{est}/hyperpolymath/proven-cicd-and-workflows/profiles/ci-gate/*/*.json").sort.each do |pf|
  p = JSON.parse(File.read(pf)); repo = p['repository']; tot[:profiles] += 1
  unless Dir.exist?("#{est}/#{repo}") then tot[:repo_not_cloned] += 1; next end
  (p['checks'] || []).each do |c|
    tot[:identities] += 1
    wf = "#{est}/#{repo}/#{c['workflow']}"
    unless File.exist?(wf) then tot[:workflow_missing] += 1; rows << [repo, c['workflow'], c['job'], 'WORKFLOW-MISSING']; next end
    y = (YAML.safe_load(File.read(wf), aliases: true) rescue nil)
    unless y.is_a?(Hash) && y['jobs'].is_a?(Hash) then tot[:workflow_unreadable] += 1; rows << [repo, c['workflow'], c['job'], 'WORKFLOW-UNREADABLE']; next end
    want = c['job']; key = want.split(' / ').first
    prod = y['jobs'].select { |id, j| j.is_a?(Hash) && ([id.to_s, j['name'].to_s].include?(want) || [id.to_s, j['name'].to_s].include?(key)) }
    if prod.empty? then tot[:no_producer] += 1; rows << [repo, c['workflow'], want, 'NO-JOB-OF-THAT-NAME']
    else tot[:producible] += 1
      if prod.values.all? { |j| j.key?('if') } then tot[:if_skippable] += 1; rows << [repo, c['workflow'], want, 'if-skippable'] end
    end
  end
end
puts "ci-gate profiles: #{tot[:profiles]} (target repo not cloned: #{tot[:repo_not_cloned]}); required identities: #{tot[:identities]}"
puts "  workflow file absent at HEAD: #{tot[:workflow_missing]}; unreadable: #{tot[:workflow_unreadable]}"
puts "  workflow present, no job of the required name (upper bound): #{tot[:no_producer]}"
puts "  producible: #{tot[:producible]}; of those, every producer has a job-level if: #{tot[:if_skippable]}"
rows.first(14).each { |r| puts "   " + r.join(" | ") }
