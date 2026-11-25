require 'yaml'; require 'digest'; require 'json'; require 'open3'
T="/home/user/estate/hyperpolymath/rsr-template-repo"
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
def h(x) Digest::SHA256.hexdigest(JSON.generate(canon(x))) end
tot=Hash.new(0)
printf "%-20s %5s | %7s %7s %7s %7s %7s | tmpl versions/views\n","name","files","rawHEAD","rawOLD","parsed","view","none"
%w[governance scorecard hypatia-scan mirror secret-scanner].each do |n|
  ids=File.readlines("tv/#{n}.ids").map(&:strip).reject{|i| i=~/^0+$/}
  headid=`git -C #{T} rev-parse HEAD:.github/workflows/#{n}.yml`.strip
  traw={}; tpar={}; tview={}
  ids.each do |id|
    s,_=Open3.capture2("git","-C",T,"cat-file","blob",id)
    traw[Digest::SHA256.hexdigest(s)]=id
    begin y=YAML.safe_load(s, aliases:true) rescue next end
    tpar[h(y)]=id; tview[h(view(y))]=id
  end
  headraw=Digest::SHA256.hexdigest(`git -C #{T} cat-file blob #{headid}`)
  c=Hash.new(0); files=0
  Dir["/home/user/estate/*/*/.github/workflows/#{n}.yml"].each do |f|
    next if f.include?("/hyperpolymath/rsr-template-repo/")
    s=File.read(f); files+=1; r=Digest::SHA256.hexdigest(s)
    if r==headraw then c[:head]+=1; next end
    if traw[r] then c[:old]+=1; next end
    begin y=YAML.safe_load(s, aliases:true) rescue (c[:none]+=1; next) end
    if tpar[h(y)] then c[:parsed]+=1
    elsif tview[h(view(y))] then c[:view]+=1
    else c[:none]+=1 end
  end
  printf "%-20s %5d | %7d %7d %7d %7d %7d | %d/%d\n", n, files, c[:head], c[:old], c[:parsed], c[:view], c[:none], ids.size, tview.size
  [:head,:old,:parsed,:view,:none].each{|k| tot[k]+=c[k]}; tot[:files]+=files
end
printf "%-20s %5d | %7d %7d %7d %7d %7d\n","TOTAL",tot[:files],tot[:head],tot[:old],tot[:parsed],tot[:view],tot[:none]
