# Run benchmarks with vegeta

vegeta attack -rate=10 -duration=30s -targets=targets.txt > results.gob
vegeta encode --to=json results.gob > results.json
vegeta plot < results.json > plot.html
open plot.html
