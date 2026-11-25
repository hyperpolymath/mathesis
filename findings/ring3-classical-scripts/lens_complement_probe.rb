#!/usr/bin/env ruby
# Read-only probe for Ring 3 candidate "quotient lens for template propagation".
# For the estate-wide wrapper workflow names, count distinct file contents under three views:
#   raw        : bytes
#   parsed     : YAML value (comments, layout, key order and quoting gone)
#   view       : YAML value with a small typed complement projected out:
#                the pin after '@' in every uses:, cron strings, the owner in a standards path,
#                and the VALUES (not keys) of `with:` on call jobs
# If `view` collapses to a handful of shapes, the variation between copies is carried by the complement
# and a lens (get = view, complement = the projected fields) exists for that name.
# Usage: ruby lens_complement_probe.rb   (run from /home/user/estate)
require 'yaml'; require 'digest'; require 'json'
NAMES = %w[secret-scanner.yml governance.yml scorecard.yml hypatia-scan.yml mirror.yml rust-ci.yml codeql.yml push-email-notify.yml labels.yml dogfood-gate.yml workflow-linter.yml dependabot-automerge.yml]
def canon(v) v.is_a?(Hash) ? v.sort_by{|k,_| k.to_s}.map{|k,x| [k.to_s, canon(x)]} : v.is_a?(Array) ? v.map{|x| canon(x)} : v end
def view(v, path=[])
  case v
  when Hash
    v.each_with_object({}) do |(k,x),h|
      ks=k.to_s
      h[ks] = if ks=="uses" && x.is_a?(String) then x.sub(%r{^(hyperpolymath|metadatastician)/standards/}, "STANDARDS/").sub(/@.*/, "@PIN")
              elsif ks=="cron" then "CRON"
              elsif ks=="with" && x.is_a?(Hash) && path.include?("jobs") then x.keys.map(&:to_s).sort
              else view(x, path+[ks]) end
    end
  when Array then v.map{|x| view(x, path)}
  else v end
end
printf "%-26s %5s %5s %6s %5s %8s %s\n", "name","files","raw","parsed","view","top-view","top-3 view shares"
NAMES.each do |n|
  raw={}; par=Hash.new(0); vw=Hash.new(0); files=0; bad=0
  Dir["*/*/.github/workflows/#{n}"].each do |f|
    s=File.read(f); files+=1; raw[Digest::SHA256.hexdigest(s)]=true
    begin y=YAML.safe_load(s, aliases:true) rescue (bad+=1; next) end
    par[Digest::SHA256.hexdigest(JSON.generate(canon(y)))]+=1
    vw[Digest::SHA256.hexdigest(JSON.generate(canon(view(y))))]+=1
  end
  top=vw.values.sort.reverse
  printf "%-26s %5d %5d %6d %5d %8d %s\n", n, files, raw.size, par.size, vw.size, top[0]||0, top.first(3).join("/")
end
