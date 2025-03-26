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

App:get("/query", function(c)
    local query = c.req:query()
    return c.json(query)
end)

App:get("/json", function(c)
    return c.json(payload)
end)

App:get("/users/:name/:id", function(c)
    return c.json({
        params = c.req:param()
    })
end)

App:get("/users/thomas/oui", function(c)
    return c.json({
        params = c.req:param()
    })
end)

App:start()
