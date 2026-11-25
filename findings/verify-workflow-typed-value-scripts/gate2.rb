require_relative 'gate'
by=Hash.new{|h,k| h[k]=[]}
File.readlines('/tmp/wfv/index2.tsv', chomp:true).each{|l| w,r,h,f,id=l.split("\t"); by[[w,r,h]] << [f, verdict(File.read("/tmp/wfv/blobs2/#{id}.pre"))]}
by.each{|(w,r,h),fs| bad=fs.reject{|f,v| v[0]=='PASS'}; puts "#{w} #{r} #{h[0,8]} files=#{fs.size} rejected=#{bad.size} #{bad.first(3).map{|f,v| File.basename(f)+':'+v[0]+' '+v[1][0,60]}.join(' | ')}"}
