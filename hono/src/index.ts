import { serve } from "@hono/node-server";
import { Hono } from "hono";
import { SmartRouter } from "hono/router/smart-router";
import { TrieRouter } from "hono/router/trie-router";

const app = new Hono();

app.get("/cool", (c) => {
    return c.text("coucou app");
});

app.router = new SmartRouter({
    routers: [new TrieRouter()],
});

function heavyComputation(size: number) {
    const numbers = Array.from({ length: size }, (_, i) => i + 1); // building [0..n+1] array length size
    const transformed = numbers.map((n) => Math.sqrt(n) * Math.pow(n, 1.5) - Math.log(n + 1)); // using sqrt pow, log, operations
    const filtered = transformed.filter((n) => n % 2 !== 0); // keeping odd numbers
    const sum = filtered.reduce((acc, val) => acc + val, 0); // summing all values in array
    return sum; // the sum
}

app.use("q/*", async (c, next) => {
    console.log("m_1");
    await next();
    console.log("m_2");
});

app.get("q/*", async (c, next) => {
    console.log("m_3");
    await next();
    console.log("m_4");
});

app.get("q/1", async (c) => {
    return c.text("hi");
});
app.get("q/2/3/4", async (c) => {
    return c.text("hi");
});

console.log(app.routes);

serve(
    {
        fetch: app.fetch,
        port: 3000,
    },
    (info) => {
        console.log(`Honojs - Server is running on http://localhost:${info.port} | ${info.address} | ${info.family}`);
    }
);
