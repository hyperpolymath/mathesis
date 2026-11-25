require_relative 'gate'
by=Hash.new{|h,k| h[k]=[]}
File.readlines('/tmp/wfv/index3.tsv', chomp:true).each{|l| w,r,h,f,id=l.split("\t"); by[[w,r,h]] << [f, verdict(File.read("/tmp/wfv/blobs3/#{id}.pre")), verdict(File.read("/tmp/wfv/blobs3/#{id}.post")), id]}
t=Hash.new{|h,k| h[k]=Hash.new(0)}
by.each{|(w,r,h),fs| bad=fs.reject{|f,v,_| v[0]=='PASS'}; t[w][:commits]+=1; t[w][bad.empty? ? :pre_all_pass : :pre_rejected]+=1; bad.each{|f,v,_| t[w]["kind:"+v[0]+' '+v[1].sub(/job \S+ /,'job ')[0,50]]+=1}
 puts "#{w} #{r} #{h[0,8]} files=#{fs.size} rejected=#{bad.size} #{bad.first(2).map{|f,v| File.basename(f)+':'+v[0]+' '+v[1][0,70]}.join(' | ')}" if ENV['V']}
t.each{|w,c| puts w; c.each{|k,v| puts "   #{k} = #{v}"}}
