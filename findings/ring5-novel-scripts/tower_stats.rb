rows = File.readlines('/tmp/r5/tower.tsv', chomp: true).map { |l| l.split("\t") }
n = rows.size
puts "files #{n}"
puts "files with >=1 call job #{rows.count { |r| r[8].to_i > 0 }}"
l4 = rows.group_by { |r| r[6] }
puts "L4 classes containing a call job #{l4.count { |_, rs| rs.any? { |r| r[8].to_i > 0 } }}"
viol = rows.group_by { |r| r[3] }.count { |_, rs| rs.map { |r| r[4] }.uniq.size > 1 }
puts "L1 classes straddling >1 L2 class (text comment-strip is not a parse quotient): #{viol}"
sz = l4.values.map(&:size).sort.reverse
puts "L4 classes #{sz.size}, singletons #{sz.count(1)}"
cum = 0; need = {}
sz.each_with_index { |s, i| cum += s; [0.5, 0.8, 0.9].each { |q| need[q] ||= i + 1 if cum >= q * n } }
puts "L4 classes needed to cover 50%/80%/90% of files: #{need[0.5]} / #{need[0.8]} / #{need[0.9]}"
# repos spanned by biggest classes
puts "top 8 L4 classes (files, distinct repos, names): " + l4.values.sort_by { |rs| -rs.size }.first(8).map { |rs| "#{rs.size}/#{rs.map { |r| r[0] }.uniq.size}/#{rs.map { |r| r[1] }.uniq.first(2).join('+')}" }.join('  ')
puts "--- per template name: files / L0 raw / L2 parsed / L3 pins-abstracted / L4 shape / L5 skeleton / largest L4 class"
rows.group_by { |r| r[1] }.select { |_, rs| rs.size >= 130 }.sort_by { |_, rs| -rs.size }.each do |nm, rs|
  c = ->(i) { rs.map { |r| r[i] }.uniq.size }
  big = rs.group_by { |r| r[6] }.values.map(&:size).max
  printf "%-28s %4d %4d %4d %4d %4d %4d %4d\n", nm, rs.size, c[2], c[4], c[5], c[6], c[7], big
end
# names with >=20 files: total files and total L4 classes
tn = rows.group_by { |r| r[1] }.select { |_, rs| rs.size >= 20 }
puts "names with >=20 files: #{tn.size} names, #{tn.values.sum(&:size)} files, L4 classes summed per name #{tn.values.sum { |rs| rs.map { |r| r[6] }.uniq.size }}, L3 #{tn.values.sum { |rs| rs.map { |r| r[5] }.uniq.size }}"
