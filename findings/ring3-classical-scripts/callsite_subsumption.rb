#!/usr/bin/env ruby
# Read-only probe for Ring 3 candidate "bump = subsumption".
# For every job-level call of a standards reusable workflow in the estate, decide whether
# moving the pin to the canon's current HEAD is interface- and effect-safe:
#   inputs   : every key the caller passes in `with:` is declared by the callee at HEAD,
#              and every callee input marked required is passed          (contravariance)
#   secrets  : every callee secret marked required is passed or `secrets: inherit`
#   effect   : callee's requested token permissions <= the caller's grant (effect subsumption)
#   presence : the callee file still exists at HEAD
# Usage: ruby callsite_subsumption.rb   (run from /home/user/estate)
require 'yaml'
STD = "metadatastician/standards/.github/workflows"
RANK = {"none"=>0,"read"=>1,"write"=>2}
def sig(path)
  y = YAML.load_file(path); need = {}
  top = y["permissions"]
  (y["jobs"]||{}).each_value do |j|
    next unless j.is_a?(Hash)
    p = j.key?("permissions") ? j["permissions"] : top
    next unless p.is_a?(Hash)
    p.each{|k,v| need[k] = (need[k]=="write"||v=="write") ? "write" : v}
  end
  on = y[true] || y["on"]; wc = (on.is_a?(Hash) ? on["workflow_call"] : nil)
  return nil unless on.is_a?(Hash) && on.key?("workflow_call")
  wc ||= {}
  {need: need, inputs: (wc["inputs"]||{}), secrets: (wc["secrets"]||{})}
end
sigs = {}; present = {}
Dir["#{STD}/*.{yml,yaml}"].each{|f| present[File.basename(f)] = true; (sigs[File.basename(f)] = sig(f)) rescue nil}
tot = Hash.new(0); verdict = Hash.new{|h,k| h[k]=Hash.new(0)}; pins = Hash.new{|h,k| h[k]={}}
parsefail = 0; sites = 0
Dir["*/*/.github/workflows/*.{yml,yaml}"].each do |f|
  begin; y = YAML.load_file(f); rescue Exception; parsefail += 1; next; end
  next unless y.is_a?(Hash) && y["jobs"].is_a?(Hash)
  top = y["permissions"]
  y["jobs"].each do |jn, j|
    next unless j.is_a?(Hash) && j["uses"].is_a?(String)
    m = j["uses"].match(%r{^(hyperpolymath|metadatastician)/standards/\.github/workflows/([A-Za-z0-9_.-]+)@(\S+)$}) or next
    wf = m[2]; sites += 1; tot[wf] += 1; pins[wf][m[3]] = true
    unless present[wf] then verdict[wf]["callee file absent at HEAD"] += 1; next end
    s = sigs[wf]
    unless s then verdict[wf]["callee no longer declares workflow_call"] += 1; next end
    grant = j.key?("permissions") ? j["permissions"] : top
    g = grant.nil? ? nil : (grant.is_a?(String) ? (grant=="read-all" ? Hash.new("read") : grant=="write-all" ? Hash.new("write") : {}) : grant)
    probs = []
    if g.nil? then probs << "no explicit grant (repo default token; undecidable offline)"
    else
      miss = s[:need].select{|k,v| RANK[(g[k]||"none").to_s].to_i < RANK[v.to_s].to_i}.keys.sort
      probs << "effect: caller lacks #{miss.join('+')}" unless miss.empty?
    end
    with = (j["with"]||{}).keys
    extra = with - s[:inputs].keys
    probs << "input: caller passes undeclared #{extra.sort.join('+')}" unless extra.empty?
    reqi = s[:inputs].select{|k,v| v.is_a?(Hash) && v["required"] && !v.key?("default")}.keys - with
    probs << "input: required #{reqi.sort.join('+')} not passed" unless reqi.empty?
    unless j["secrets"] == "inherit"
      reqs = s[:secrets].select{|k,v| v.is_a?(Hash) && v["required"]}.keys - ((j["secrets"].is_a?(Hash) ? j["secrets"] : {}).keys)
      probs << "secret: required #{reqs.sort.join('+')} not passed" unless reqs.empty?
    end
    verdict[wf][probs.empty? ? "SAFE" : probs.join("; ")] += 1
  end
end
puts "call sites: #{sites}   workflow files failing YAML parse (skipped): #{parsefail}"
allsafe = 0
tot.sort_by{|k,v| -v}.each do |wf,t|
  allsafe += verdict[wf]["SAFE"]
  puts "\n#{wf}  sites=#{t}  distinct pins=#{pins[wf].size}"
  verdict[wf].sort_by{|k,v| -v}.each{|k,v| puts "   %5d  %s" % [v,k]}
end
puts "\nTOTAL SAFE to move to HEAD: #{allsafe} of #{sites}"
