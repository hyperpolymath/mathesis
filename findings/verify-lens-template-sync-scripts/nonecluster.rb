require 'yaml'; require 'digest'; require 'json'; require 'open3'
load_src = File.read("viewmatch.rb").split("tot=Hash.new(0)")[0]; eval(load_src)
%w[governance scorecard hypatia-scan mirror secret-scanner].each do |n|
  ids=File.readlines("tv/#{n}.ids").map(&:strip).reject{|i| i=~/^0+$/}
  traw={}; tpar={}; tview={}
  ids.each{|id| s,_=Open3.capture2("git","-C",T,"cat-file","blob",id); traw[Digest::SHA256.hexdigest(s)]=1; begin y=YAML.safe_load(s, aliases:true) rescue next end; tpar[h(y)]=1; tview[h(view(y))]=1}
  cl=Hash.new{|hh,k| hh[k]=[]}; unparse=0
  Dir["/home/user/estate/*/*/.github/workflows/#{n}.yml"].each do |f|
    next if f.include?("/hyperpolymath/rsr-template-repo/")
    s=File.read(f); next if traw[Digest::SHA256.hexdigest(s)]
    begin y=YAML.safe_load(s, aliases:true) rescue (unparse+=1; next) end
    next if tpar[h(y)] || tview[h(view(y))]
    cl[h(view(y))] << f
  end
  sz=cl.values.map(&:size).sort.reverse
  printf "%-16s none=%d unparseable=%d clusters=%d top=%s singletons=%d  in clusters>=5: %d\n", n, sz.sum+unparse, unparse, sz.size, sz.first(6).join("/"), sz.count(1), sz.select{|x| x>=5}.sum
  top=cl.max_by{|_,v| v.size}; puts "   example of top cluster: #{top[1][0]}" if top
end
