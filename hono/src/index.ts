import { serve } from "@hono/node-server";
import { Hono } from "hono";

const app = new Hono();

app.get("/", (c) => {
    return c.json({
        message: "Hono model main route",
    });
});

function heavyComputation(size: number) {
    const numbers = Array.from({ length: size }, (_, i) => i + 1); // building [0..n+1] array length size
    const transformed = numbers.map((n) => Math.sqrt(n) * Math.pow(n, 1.5) - Math.log(n + 1)); // using sqrt pow, log, operations
    const filtered = transformed.filter((n) => n % 2 !== 0); // keeping odd numbers
    const sum = filtered.reduce((acc, val) => acc + val, 0); // summing all values in array
    return sum; // the sum
}

app.get("/heavy", (c) => {
    const result = heavyComputation(100000);
    return c.json({
        data: result,
    });
});

serve(
    {
        fetch: app.fetch,
        port: 3000,
    },
    (info) => {
        console.log(`Server is running on http://localhost:${info.port} | ${info.address} | ${info.family}`);
    }
);
