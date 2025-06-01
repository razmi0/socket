local Server = require("lib/server")
local app = require("lib/app").new()
local logger = require("lib/middleware/logger")
local static = require("lib/middleware/static")

app:use("*", logger())
app:on("GET", { "/", "/:file{^.+%.%w+}" }, static(
    function(c)
        return "public" .. "/" .. (c.req:param("file") or "index.html")
    end)
)


Server.new(app):start()
