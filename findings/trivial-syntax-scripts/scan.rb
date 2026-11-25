require 'psych'; require 'json'
SKIP=%r{(^|/)(node_modules|vendor|target|\.lake|deps|_build|\.git|third_party|build|dist|\.deno|elm-stuff|fixtures?|testdata|test-fixtures|samples)(/|$)}
JSONC=%r{(^|/)(\.devcontainer|\.vscode|tsconfig[^/]*\.json|devcontainer\.json|\.eslintrc\.json|deno\.jsonc?|bsconfig\.json)}
def dupkeys(node, path, out)
  case node
  when Psych::Nodes::Mapping
    seen={}
    node.children.each_slice(2){|k,v| if k.is_a?(Psych::Nodes::Scalar); key=k.value; (out << key) if seen[key]; seen[key]=true; end; dupkeys(v,path,out)}
  when Psych::Nodes::Sequence, Psych::Nodes::Document, Psych::Nodes::Stream
    node.children.each{|c| dupkeys(c,path,out)}
  end
end
res=Hash.new{|h,k|h[k]=[]}
cnt=Hash.new(0)
Dir.glob("/home/user/estate/*/*").sort.each do |repo|
  next unless File.directory?(repo)
  rn=repo.sub('/home/user/estate/','')
  files=Dir.glob("#{repo}/**/*",File::FNM_DOTMATCH).select{|f| File.file?(f) && !File.symlink?(f)}
  files.each do |f|
    rel=f.sub("#{repo}/",'')
    next if rel=~SKIP || rel.start_with?('.git/')
    ext=File.extname(rel).downcase
    wf = rel=~%r{^\.github/workflows/[^/]+\.ya?ml$}
    begin
      if wf || ext=='.yml' || ext=='.yaml' || ext=='.kyaml'
        sz=File.size(f); next if sz>2_000_000
        s=File.binread(f).force_encoding('UTF-8')
        cnt[wf ? 'wf_total' : 'yaml_other_total']+=1
        begin
          doc=Psych.parse_stream(s)
          d=[]; dupkeys(doc,rel,d)
          if d.any? then res[wf ? 'wf_dupkey' : 'yaml_dupkey'] << "#{rn}:#{rel}:#{d.uniq.first(3).join('|')}" end
        rescue Psych::SyntaxError => e
          res[wf ? 'wf_parse_fail' : 'yaml_parse_fail'] << "#{rn}:#{rel}:#{e.message[0,80].gsub(/\s+/,' ')}"
        end
        if s.include?("\r\n") then res['yaml_crlf'] << "#{rn}:#{rel}" end
        if wf && s =~ /^npermissions:/ then res['npermissions_residue'] << "#{rn}:#{rel}" end
        if wf && !(s=~/\A(?:#[^\n]*\n)*?#\s*SPDX-License-Identifier:/) then res['wf_no_spdx_head'] << "#{rn}:#{rel}" end
        if wf && !s.end_with?("\n") then res['wf_no_final_nl'] << "#{rn}:#{rel}" end
      elsif ext=='.json' || ext=='.jsonc'
        next if rel=~JSONC || ext=='.jsonc'
        sz=File.size(f); next if sz>5_000_000
        s=File.binread(f).force_encoding('UTF-8')
        cnt['json_total']+=1
        begin; JSON.parse(s); rescue JSON::ParserError => e; res['json_parse_fail'] << "#{rn}:#{rel}:#{e.message[0,60].gsub(/\s+/,' ')}"; end
        res['json_bom'] << "#{rn}:#{rel}" if s.start_with?("\xEF\xBB\xBF")
        res['json_no_final_nl'] << "#{rn}:#{rel}" if !s.empty? && !s.end_with?("\n")
      elsif ext=='.deed'
        s=File.binread(f).force_encoding('UTF-8'); cnt['deed_total']+=1
        # paren balance ignoring strings/comments
        t=s.gsub(/"(?:\\.|[^"\\])*"/m,'""').gsub(/;[^\n]*/,''); o=t.count('('); c=t.count(')')
        res['deed_paren_imbalance'] << "#{rn}:#{rel}:#{o}/#{c}" if o!=c
      end
    rescue => e
      res['scan_error'] << "#{rn}:#{rel}:#{e.class}"
    end
  end
end
File.write('/tmp/ts/scan/counts.json',JSON.generate(cnt))
res.each{|k,v| File.write("/tmp/ts/scan/#{k}.txt",v.join("\n")+"\n")}
puts JSON.pretty_generate(cnt); res.each{|k,v| puts "#{k}: #{v.size} files in #{v.map{|x|x.split(':')[0]}.uniq.size} repos"}
