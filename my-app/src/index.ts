import { serve } from "@hono/node-server";
import { Hono } from "hono";

const app = new Hono();

// app.get("a/b/c", (c) => {
//     return c.text("Hello Hono!");
// });

app.post("/a/b/c", (c) => {
    return c.text("Hello Hono!");
});

serve(
    {
        fetch: app.fetch,
        port: 3000,
    },
    (info) => {
        console.log(`Server is running on http://localhost:${info.port}`);
    }
);
