local server = require("lib/server")
local logger = require("lib/middleware/logger")
local serve = require("lib/middleware/static")
local app = require("lib/app").new()

app:use("*", logger())
app:get("*", serve({ root = "public" }))
server.new(app):start()
