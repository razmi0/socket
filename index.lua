local App = require("lib/server")
local inspect = require("lib/utils")

local payload = {
    some_object = {
        foo = "bar"
    },
    some_array = { "foo", "bar", "baz" }
}

App:get("/", function(c)
    return c.html(
        [[
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <meta http-equiv="X-UA-Compatible" content="ie=edge">
            <meta name="google" content="notranslate">
            <title>Hello world</title>
            <link href="https://cdn.jsdelivr.net/npm/beercss@3.9.7/dist/cdn/beer.min.css" rel="stylesheet">
            <script type="module" src="https://cdn.jsdelivr.net/npm/beercss@3.9.7/dist/cdn/beer.min.js"></script>
            <script type="module" src="https://cdn.jsdelivr.net/npm/material-dynamic-colors@1.1.2/dist/cdn/material-dynamic-colors.min.js"></script>
        </head>
        <body>
         <header class="tertiary-container">
            <nav>
                <button class="active tertiary">
                    <span> links </span>
                    <i>arrow_drop_down</i>
                    <menu class="border no-wrap">
                        <li><a href="/">Home</a></li>
                        <li><a href="/query?foo=bar">Query</a></li>
                        <li><a href="/json">JSON</a></li>
                        <li><a href="/users/thomas/oui">No params</a></li>
                        <li><a href="/users/nao/123">With params</a></li>
                    </menu>
                </button>
            </nav>
        </header>
            <h1>Some HTML</h1>
        </body>
        </html>
        ]]
    )
end)

App:get("/query", function(c)
    local query = c.req:query()
    return c.json({ query = query })
end)

App:get("/json", function(c)
    return c.json({ json = payload })
end)

App:get("/users/:name/:id", function(c)
    return c.json({
        with_params = c.req:param()
    })
end)

App:get("/users/thomas/oui", function(c)
    return c.json({
        without_params = c.req:param()
    })
end)

App:start()
