#!/bin/bash



# Run Hono
echo "Bench hono-js" &&

vegeta attack -rate=10 -duration=10s -targets=benchmark/targets.txt > benchmark/results/hono-js/results.gob &&
vegeta encode --to=json benchmark/results/hono-js/results.gob > benchmark/results/hono-js/results.json &&
vegeta plot < benchmark/results/hono-js/results.json > benchmark/results/hono-js/plot.html &&

echo "Ended"

