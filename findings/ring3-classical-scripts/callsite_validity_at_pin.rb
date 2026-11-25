#!/usr/bin/env ruby
# Read-only probe for Ring 3 candidate "bump = subsumption": validity of each call site AT ITS OWN PIN.
# For every job-level call of a standards reusable workflow pinned by a 40-hex SHA, read the callee file at
# that SHA from the local standards clone (one blob per distinct (sha, file) pair) and decide:
#   request(callee@pin) <= grant(calling job)   where request = permissions declared at the callee's top
#   level or on any of its jobs, and grant = the calling job's permissions block if present, else the
#   caller's top-level block (a job-level block replaces the top-level one).
# GitHub's rule, as the estate records it (Cytoville cf7b8ed, enaction-engine b3f89f0): a called workflow
# cannot request more than the caller grants; the run is refused before any job starts.
# Usage: ruby callsite_validity_at_pin.rb   (run from /home/user/estate)
require "yaml"; require "open3"
Encoding.default_external = Encoding::UTF_8; Encoding.default_internal = nil
STD = "metadatastician/standards"; RANK = {"none"=>0,"read"=>1,"write"=>2}
$sig = {}
def sig(sha, wf)
  $sig[[sha,wf]] ||= begin
    out, st = Open3.capture2e("git","-C",STD,"cat-file","-p","#{sha}:.github/workflows/#{wf}")
    out = out.dup.force_encoding("UTF-8")
    if !st.success? then :absent
    else
      y = (YAML.safe_load(out, aliases:true) rescue nil)
      if !y.is_a?(Hash) then :unparseable
      else
        need = {}
        ([y["permissions"]] + (y["jobs"]||{}).values.map{|j| j.is_a?(Hash) ? j["permissions"] : nil}).compact.each do |p|
          next unless p.is_a?(Hash); p.each{|k,v| need[k] = (need[k]=="write"||v=="write") ? "write" : v}
        end
        on = y[true] || y["on"]; wc = (on.is_a?(Hash) ? on["workflow_call"] : nil) || {}
        {need: need, inputs: (wc["inputs"]||{}), called: (on.is_a?(Hash) && on.key?("workflow_call"))}
      end
    end
  end
end
res = Hash.new(0); detail = Hash.new(0); rows = []
Dir["*/*/.github/workflows/*.{yml,yaml}"].sort.each do |f|
  y = (YAML.load_file(f) rescue next); next unless y.is_a?(Hash) && y["jobs"].is_a?(Hash)
  top = y["permissions"]
  y["jobs"].each do |jn,j|
    next unless j.is_a?(Hash) && j["uses"].is_a?(String)
    m = j["uses"].match(%r{^(hyperpolymath|metadatastician)/standards/\.github/workflows/([A-Za-z0-9_.-]+)@([0-9a-f]{40})$}) or next
    s = sig(m[3], m[2])
    if s == :absent then res["pin or file does not resolve in the local canon clone"] += 1; rows << [f,jn,m[2],m[3][0,8],"UNRESOLVED"]; next end
    if s == :unparseable then res["callee unparseable at pin"] += 1; next end
    unless s[:called] then res["callee does not declare workflow_call at pin"] += 1; rows << [f,jn,m[2],m[3][0,8],"NOT-CALLABLE"]; next end
    grant = j.key?("permissions") ? j["permissions"] : top
    if grant.nil? then res["no explicit grant (undecidable offline)"] += 1; next end
    g = grant.is_a?(String) ? (grant=="read-all" ? Hash.new("read") : grant=="write-all" ? Hash.new("write") : {}) : grant
    miss = s[:need].select{|k,v| RANK[(g[k]||"none").to_s].to_i < RANK[v.to_s].to_i}.keys.sort
    extra = ((j["with"]||{}).keys - s[:inputs].keys).sort
    if miss.empty? && extra.empty? then res["valid at pin"] += 1
    else
      why = []; why << "lacks #{miss.join('+')}" unless miss.empty?; why << "passes undeclared input #{extra.join('+')}" unless extra.empty?
      res["INVALID at pin"] += 1; detail["#{m[2]}: #{why.join('; ')}"] += 1; rows << [f,jn,m[2],m[3][0,8],why.join('; ')]
    end
  end
end
puts "distinct (pin, callee) pairs read: #{$sig.size}"
res.sort_by{|k,v| -v}.each{|k,v| puts "%6d  %s" % [v,k]}
puts "--- INVALID at pin, by cause"
detail.sort_by{|k,v| -v}.each{|k,v| puts "%6d  %s" % [v,k]}
File.write(File.join(File.dirname(__FILE__), "callsite_validity_at_pin.rows.tsv"), rows.map{|r| r.join("\t")}.join("\n")+"\n")
