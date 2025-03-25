local App = require("lib/server")


local run = function(c)
    local method = c.req.method
    local path = c.req.path
    c.res:setBody("{\"method\": \"" .. method .. "\", \"path\": \"" .. path .. "\"}"):send()
end

App:get("/", run)
App:post("/", run)


App:start({ port = 8080 })
