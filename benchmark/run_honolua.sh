#!/bin/bash



# Run Lua-Hono
echo "Bench hono-lua" &&

vegeta attack -rate=10 -duration=10s -targets=benchmark/targets.txt > benchmark/results/hono-lua/results.gob &&
vegeta encode --to=json benchmark/results/hono-lua/results.gob > benchmark/results/hono-lua/results.json &&
vegeta plot < benchmark/results/hono-lua/results.json > benchmark/results/hono-lua/plot.html &&


echo "Ended"
