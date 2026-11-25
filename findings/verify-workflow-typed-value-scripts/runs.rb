# Read-only: size of the "diode" migration: run: scalars by line count, and expression holes inside them.
require 'yaml'
tot=0; ml=0; hist=Hash.new(0); files_with=0; expr_in_run=0; lines_total=0; uses_steps=0; steps=0
Dir["*/*/.github/workflows/*.{yml,yaml}"].sort.each do |f|
  y=(YAML.safe_load(File.read(f), aliases:true) rescue nil); next unless y.is_a?(Hash) && y['jobs'].is_a?(Hash)
  any=false
  y['jobs'].each_value do |j| next unless j.is_a?(Hash) && j['steps'].is_a?(Array)
    j['steps'].each do |s| next unless s.is_a?(Hash); steps+=1
      uses_steps+=1 if s.key?('uses')
      r=s['run']; next unless r.is_a?(String)
      tot+=1; any=true; n=r.lines.count; lines_total+=n
      ml+=1 if n>1
      b = n<=1 ? '1' : n<=5 ? '2-5' : n<=20 ? '6-20' : n<=50 ? '21-50' : '>50'
      hist[b]+=1
      expr_in_run+=1 if r.include?('${{')
    end
  end
  files_with+=1 if any
end
puts "steps #{steps}; uses-steps #{uses_steps}; run scalars #{tot} in #{files_with} files; multi-line #{ml}; total script lines #{lines_total}"
puts "run scalars interpolating ${{ }} directly: #{expr_in_run}"
%w[1 2-5 6-20 21-50 >50].each{|k| puts "  #{k} lines: #{hist[k]}"}
