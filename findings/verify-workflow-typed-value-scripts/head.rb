require '/tmp/wfv/gate'
c=Hash.new(0); ex=Hash.new{|h,k| h[k]=[]}; va=Hash.new(0); scopes=Hash.new(0)
Dir["*/*/.github/workflows/*.{yml,yaml}"].sort.each do |f|
  s=File.read(f, mode:'rb'); v=verdict(s); c[v[0]]+=1
  k=v[1].sub(/job \S+ /,'job ').sub(/line \d+ column \d+/,'').sub(/^\/jobs\/[^\/]+/,'/jobs/*')[0,60]; ex[[v[0],k]] << f unless v[0]=='PASS'
  y=(YAML.safe_load(s.force_encoding('UTF-8'), aliases:true) rescue nil); next unless y.is_a?(Hash)
  ps=[y['permissions']]; (y['jobs'].is_a?(Hash) ? y['jobs'].values : []).each{|j| ps << j['permissions'] if j.is_a?(Hash)}
  ps.each{|p| next unless p.is_a?(Hash); p.each{|sc,val| scopes[sc.to_s]+=1; va[val.to_s]+=1 if sc.to_s=='vulnerability-alerts'}}
end
p c
ex.sort_by{|k,v| -v.size}.each{|k,v| puts "#{v.size}\t#{k.join(' :: ')}\t e.g. #{v.first}"}
puts "vulnerability-alerts values: #{va.inspect}"
puts "scopes in use: "+scopes.sort_by{|k,v| -v}.map{|k,v| "#{k}=#{v}"}.join(' ')
