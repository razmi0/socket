# Usage

```bash
    node watch.js src/index.lua . localhost 5050 --quiet
```

and src/index.lua:

```lua
local App = require("lib/server")


-- ...your code 

app:start({
    host = "0.0.0.0",
    port = 5050
})
```

host and port are optional

## Samples

```lua
local server = require("lib/server")
local logger = require("lib/middleware/logger")
local serve = require("lib/middleware/static")
local app = require("lib/app").new()

app:use("*", logger())
app:get("*", serve({ root = "public" }))
server.new(app):start()
```

```lua
app:get("/", function(c)
    return c.html("<h1>Some HTML</h1>")
end)
```

```lua
local static = require("lib/middleware/static")
app:get("*", static({ root = "public" }))
```

```lua
local static = require("lib/middleware/static")
app:on("GET", { "/", "/:file{^.+%.%w+}" }, static(function(c)
    return {
        root = "public",
        path = c.req:param("file") or "index.html"
    }
end)
)
```

```lua
local logger = require("lib/middleware/logger")
app:use("*", logger())
```
