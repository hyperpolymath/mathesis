#!/usr/bin/env ruby
# Read-only probe for Ring 3 candidate "workflow as an algebraic data type".
# Classifies every job in every top-level workflow file at HEAD into the two constructors GitHub's
# documented syntax allows, and reports the jobs that inhabit neither:
#   StepsJob : has runs-on and steps, no uses
#   CallJob  : has uses, and only keys from {name, uses, with, secrets, needs, if, permissions, concurrency, strategy}
# Also counts duplicate mapping keys per file (a record type has unique labels), using Psych's event stream.
# Usage: ruby job_sum_type_probe.rb   (run from /home/user/estate)
require 'yaml'
CALL_OK = %w[name uses with secrets needs if permissions concurrency strategy]
class DupFinder < Psych::Handler
  attr_reader :dups
  def initialize; @stack=[]; @dups=[]; end
  def start_mapping(*) ; @stack.push({keys:{}, expect_key:true, map:true}); end
  def end_mapping; @stack.pop; mark; end
  def start_sequence(*); @stack.push({map:false}); end
  def end_sequence; @stack.pop; mark; end
  def scalar(value,*)
    top=@stack.last
    if top && top[:map] && top[:expect_key]
      @dups << value if top[:keys][value]; top[:keys][value]=true; top[:expect_key]=false
    else mark end
  end
  def alias(*); mark; end
  def mark; top=@stack.last; top[:expect_key]=true if top && top[:map]; end
end
files=0; parsefail=[]; jobs=0; steps=0; call=0; neither=[]; dupfiles=[]
Dir["*/*/.github/workflows/*.{yml,yaml}"].sort.each do |f|
  files+=1
  src=File.read(f)
  begin
    h=DupFinder.new; Psych::Parser.new(h).parse(src); dupfiles << [f,h.dups.uniq] unless h.dups.empty?
    y=YAML.safe_load(src, aliases:true)
  rescue Exception => e
    parsefail << f; next
  end
  next unless y.is_a?(Hash) && y["jobs"].is_a?(Hash)
  y["jobs"].each do |jn,j|
    jobs+=1
    unless j.is_a?(Hash) then neither << [f,jn,"not a mapping"]; next end
    if j.key?("uses")
      bad = j.keys - CALL_OK
      if bad.empty? then call+=1 else neither << [f,jn,"call job with #{bad.sort.join('+')}"] end
    elsif j.key?("runs-on") && j.key?("steps") then steps+=1
    else neither << [f,jn,"no uses, missing #{(%w[runs-on steps]-j.keys).join('+')}"] end
  end
end
puts "workflow files: #{files}; fail to parse: #{parsefail.size}"
parsefail.each{|f| puts "   PARSE #{f}"}
puts "jobs: #{jobs}; StepsJob: #{steps}; CallJob: #{call}; inhabit neither constructor: #{neither.size}"
neither.each{|f,j,w| puts "   NEITHER #{f} :: #{j} :: #{w}"}
puts "files with a duplicate mapping key: #{dupfiles.size}"
dupfiles.each{|f,d| puts "   DUP #{f} :: #{d.join(',')}"}
