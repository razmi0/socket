local Raz = require("lib/server")

local run = function(req, res)
    local method = req:getMethod()
    local path = req:getPath()
    local protocol = req:getProtocol()


    res:setBody(
        "{\"message\": \"Hello, World  ti!\"}"
    ):send()
end

Raz:start(run, {
    host = "localhost",
    port = 8080,
})
