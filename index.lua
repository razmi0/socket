local Raz = require("lib/server")

local run = function(c)
    c.res:setBody(
        "{\"message\": \"Hello, World \"}"
    ):send()
end

Raz:start(run, { port = 8080 })
