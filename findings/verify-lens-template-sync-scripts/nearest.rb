require 'yaml'; require 'digest'; require 'json'; require 'open3'
eval(File.read("viewmatch.rb").split("tot=Hash.new(0)")[0])
def flat(v,p="",o={}) ; case v; when Hash then v.each{|k,x| flat(x,"#{p}/#{k}",o)}; when Array then v.each_with_index{|x,i| flat(x,"#{p}[#{i}]",o)}; else o[p]=v end; o end
[["governance","/home/user/estate/catachresis-colloquium/blue-screen-of-app/.github/workflows/governance.yml"],["mirror","/home/user/estate/catachresis-colloquium/airborne-submarine-squadron/.github/workflows/mirror.yml"],["hypatia-scan","/home/user/estate/catachresis-colloquium/airborne-submarine-squadron/.github/workflows/hypatia-scan.yml"]].each do |n,f|
  cv=flat(view(YAML.safe_load(File.read(f),aliases:true)))
  best=nil
  File.readlines("tv/#{n}.ids").map(&:strip).reject{|i| i=~/^0+$/}.each do |id|
    s,_=Open3.capture2("git","-C",T,"cat-file","blob",id); y=(YAML.safe_load(s,aliases:true) rescue next)
    tv=flat(view(y)); d=(cv.keys|tv.keys).select{|k| cv[k]!=tv[k]}
    best=[d.size,id,d,tv] if best.nil? || d.size<best[0]
  end
  puts "== #{n}: nearest template version #{best[1][0,9]} differs in #{best[0]} leaf paths"
  best[2].first(12).each{|k| puts "   #{k}: child=#{cv[k].inspect[0,70]} template=#{best[3][k].inspect[0,70]}"}
end
