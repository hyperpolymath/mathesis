# For each (claim ...) in each proof-receipt deed: the legs, and for the CURRENT receipt of each leg the run id and checker.
# Reports how many claims have all current receipts in one CI run / one environment pin (a shared support element).
tot = 0; same_run = 0; multi = 0; rows = []
File.readlines('/tmp/r5/receipt_deeds.txt', chomp: true).each do |f|
  txt = File.read(f, encoding: 'UTF-8')
  repo = f.split('/')[1, 2].join('/')
  txt.split(/\(claim /)[1..].to_a.each do |blk|
    id = blk[/:id "([^"]+)"/, 1]; pwg = blk[/:pwg (\S+)/, 1]
    legs = blk.split(/\(leg /)[1..].to_a.map do |lb|
      prover = lb[/:prover (\S+)/, 1]; route = lb[/:route (\S+)/, 1]; state = lb[/:state (\S+)/, 1]
      cur = lb.split(/\(receipt /)[1..].to_a.find { |rb| rb =~ /:state current/ }
      run = cur && cur[/:run "([^"]+)"/, 1]; chk = cur && cur[/:checker "([^"]+)"/, 1]
      [prover, route, state, run && run[/runs\/(\d+)/, 1], chk]
    end
    cur = legs.select { |l| l[3] }
    tot += 1
    if cur.size >= 2
      multi += 1
      same_run += 1 if cur.map { |l| l[3] }.uniq.size == 1
    end
    rows << [repo, id, pwg, legs.map { |l| "#{l[0]}/#{l[1]}/#{l[2]}/run#{l[3] || '-'}" }.join(' ')].join("\t")
  end
end
puts "claims: #{tot}; claims with >=2 legs holding a current receipt: #{multi}; of those, all current receipts from ONE CI run: #{same_run}"
File.write('/tmp/r5/receipt_supports.tsv', rows.join("\n") + "\n")
