# Usage

```bash
./start.sh 127.0.0.1 8080

# or

lua index.lua 127.0.0.1 8080
```

or programatically:

```lua
local App = require("lib/server")
App:start({
    host = "0.0.0.0",
    port = 5050
})
```

host and port are optional, they will default to "127.0.0.1" and 8080 respectively.

## Samples

```lua
App:get("/", function(c)
    return c.html("<h1>Some HTML</h1>")
end)
```
