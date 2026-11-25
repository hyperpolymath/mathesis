require_relative 'gate'
by=Hash.new{|h,k| h[k]=[]}
File.readlines('/tmp/wfv/index.tsv', chomp:true).each{|l| w,r,h,d,f,id=l.split("\t"); by[[w,r,h]] << [f,id]}
t=Hash.new{|h,k| h[k]=Hash.new(0)}
by.each do |(w,r,h),fs|
  pre=fs.map{|f,id| verdict(File.read("/tmp/wfv/blobs/#{id}.pre"))[0]}
  post=fs.map{|f,id| verdict(File.read("/tmp/wfv/blobs/#{id}.post"))[0]}
  t[w][:commits]+=1
  layer = pre.include?('L1-parse') ? 'L1' : pre.include?('L2-dup') ? 'L2' : pre.include?('L3-schema') ? 'L3' : 'NONE'
  t[w]["caught_by_#{layer}"]+=1
  t[w][:post_clean]+=1 if post.all?{|x| x=='PASS'}
  puts "  MISS #{w} #{r} #{h[0,10]} files=#{fs.map{|f,_| File.basename(f)}.join(',')}" if layer=='NONE'
end
t.sort.each{|w,c| puts "#{w}\t"+c.map{|k,v| "#{k}=#{v}"}.join("  ")}
