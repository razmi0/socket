import { serve } from "@hono/node-server";
import { Hono } from "hono";

const app = new Hono();

function heavyComputation(size: number) {
    const numbers = Array.from({ length: size }, (_, i) => i + 1); // building [0..n+1] array length size
    const transformed = numbers.map((n) => Math.sqrt(n) * Math.pow(n, 1.5) - Math.log(n + 1)); // using sqrt pow, log, operations
    const filtered = transformed.filter((n) => n % 2 !== 0); // keeping odd numbers
    const sum = filtered.reduce((acc, val) => acc + val, 0); // summing all values in array
    return sum; // the sum
}

app.get("/heavy", (c) => {
    const result = heavyComputation(100);
    return c.json({
        data: result,
    });
});

app.get(
    "/chain",
    // Middleware 1
    async (c, next) => {
        c.set("key-1", " wo");
        await next();
        c.header(c.get("handler-1")!, "done");
    },
    // Middleware 2
    async (c, next) => {
        c.set("key-2", "rld");
        await next();
        c.header(c.get("handler-2")!, "done");
    },
    // Handler
    (c) => {
        c.set("handler-1", "X-Middleware-1");
        c.set("handler-2", "X-Middleware-2");
        return c.json({
            json: "Hello" + c.get("key-1") + c.get("key-2"),
        });
    }
);

serve(
    {
        fetch: app.fetch,
        port: 3000,
    },
    (info) => {
        console.log(`Honojs - Server is running on http://localhost:${info.port} | ${info.address} | ${info.family}`);
    }
);
