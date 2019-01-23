counts = Hash.new(0)

100.times do
  output = `curl -s canary.com | grep 'Canary' | awk '{print $2}' | awk -F"<" '{print $1}'`
  counts[output.strip.split.last] += 1
end

puts counts
