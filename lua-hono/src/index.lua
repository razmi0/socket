local Server = require("lib/server")
local app = require("lib/app").new()
local logger = require("lib.middleware.logger")

app:use("*", logger())
app:get("/hello", function(c)
    return c:json({ message = "Hello" })
end)

Server.new(app):start()
