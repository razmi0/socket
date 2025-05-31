local Server = require("lib/server")
local app = require("lib/app").new()
local logger = require("lib.middleware.logger")

app:use("*", logger())
app:get("/a/b/c", function(c)
    return c:json({ message = "static a/b/c" })
end)
app:get("/a/:b/c", function(c)
    return c:json({ message = "dyn a/:b/c" })
end)

Server.new(app):start()
