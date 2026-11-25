# Read-only census of features a "value then print" pipeline has to preserve or lose.
require 'yaml'
n=0; anchors=0; body_comments=0; inline_comments=0; hdr_only=0; nocom=0; multi=0; flow=0; folded=0; quoted_on=0; crlf=0; tabs=0
runlines=Hash.new(0); runs=0; run_ml=0; big=0; expr_files=0
Dir["*/*/.github/workflows/*.{yml,yaml}"].sort.each do |f|
  s=File.read(f, mode:'rb').force_encoding('UTF-8'); next unless s.valid_encoding?
  n+=1
  lines=s.lines
  crlf+=1 if s.include?("\r\n")
  anchors+=1 if s =~ /^\s*[^#\n]*:\s+&\w+|^\s*-\s+&\w+|<<:\s*\*|:\s+\*\w+\s*$/
  # leading header comment block
  i=0; i+=1 while i<lines.size && (lines[i] =~ /^\s*#/ || lines[i].strip.empty?)
  rest=lines[i..]||[]
  # crude: comment lines outside block scalars -- track block scalar by indent
  inblk=nil; bc=0; ic=0
  rest.each do |l|
    ind=l[/^ */].size
    if inblk
      if l.strip.empty? || ind>inblk then next else inblk=nil end
    end
    if l =~ /^\s*#/ then bc+=1; next end
    ic+=1 if l =~ /\s#\s/ && l !~ /:\s*[|>]/ && l !~ /["'].*#.*["']/
    inblk=ind if l =~ /:\s*[|>][+-]?\d?\s*(#.*)?$/ || l =~ /^\s*-\s*[|>][+-]?\s*$/
  end
  if bc>0 then body_comments+=1 end
  inline_comments+=1 if ic>0
  hdr_only+=1 if bc==0 && ic==0 && i>0
  nocom+=1 if bc==0 && ic==0 && i==0
  flow+=1 if s =~ /^\s*[\w-]+:\s*[\[{]/
  folded+=1 if s =~ /:\s*>[+-]?\s*$/
  expr_files+=1 if s.include?('${{')
end
puts "files #{n}; anchors/aliases #{anchors}; CRLF #{crlf}"
puts "comment lines in body (outside header, outside block scalars): #{body_comments} files; trailing inline comments: #{inline_comments} files"
puts "header-comment only: #{hdr_only}; no comments at all: #{nocom}"
puts "flow collections ([..]/{..} values): #{flow}; folded scalars (>): #{folded}; files with ${{ }} expressions: #{expr_files}"
