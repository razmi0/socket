local App = require("lib/server")

local run = function(c)
    local method = c.req.method
    local path = c.req.path
    c.header("X-Powered-By", "Raz")
    c.status(202)
    c.body("{\"method\": \"" .. method .. "\", \"path\": \"" .. path .. "\"}")
    c.res:send()
end

App:get("/", run)
App:post("/", run)

App:start({
    port = 8080
})
