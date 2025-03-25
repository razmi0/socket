local App = require("lib/server")
local inspect = require("lib/utils")

local payload = {
    some_object = {
        foo = "bar"
    },
    some_array = {"foo", "bar", "baz"}
}

App:get("/", function(c)
    return c.html("<h1>Home page</h1>")
end)

App:get("/json", function(c)
    local query = c.req.query()
    if query then
        return c.json({
            query = query
        })
    end
    return c.json(payload)
end)

App:get("/json/:id/:name/new", function(c)
    return c.json(payload)
end)

App:start({
    port = 8080
})
