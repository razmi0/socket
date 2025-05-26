local Server = require("lib/server")
local app = require("lib/app").new()
local logger = require("lib.middleware.logger")

app:use("*", function(c, next)
    print("-->", c.req.path, c.req.method)
    next()
    print("<--", c.res.status, c.req.method)
end)
app:get("/hello", function(c) return c:text("hello") end)

Server.new(app):start()
