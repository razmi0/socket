# Run benchmarks with vegeta

benchmarks runs with vegeta. Honojs in Node. The other lua.

results are outputed to benchmark/results/hono-\* in json, gob and html format

localhost/heavy endpoints of the lua and js versions are pinged :

-   10 request / s
-   for duration 10s
-   total of 100 request

uri pinged : GET <http://localhost:3000/heavy>

/heavy is a slow process

## Usage

### Honojs

```bash
./start-hono.sh
```

& in another terminal :

```bash
benchmark/run_honojs.sh
```

To see the results in browser :

```bash
open benchmark/results/hono-js/plot.html
```

### HonoLua

```bash
./start-lua-hono.sh
```

& in another terminal :

```bash
benchmark/run_honolua.sh
```

To see the results in browser :

```bash
open benchmark/results/hono-lua/plot.html
```

## Usage

## Observation

**Latency-Lua = Latency-Hono \* 2 :**

for a 10ms increase in hono js, there's a 20ms increase in hono lua
honojs async I/O operations (Concurrent Operation) are outperformming sync flow of lua ( Sequential Operation ) and scale better.

```

```
