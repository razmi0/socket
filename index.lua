local App = require("lib/server")
local inspect = require("lib/utils")

local payload = {
    some_object = {
        foo = "bar"
    },
    some_array = { "foo", "bar", "baz" }
}

App:get("/", function(c)
    return c.html("<h1>Some HTML brè</h1>")
end)

App:get("/query", function(c)
    local query = c.req:query()
    return c.json({ query = query })
end)

App:get("/json", function(c)
    return c.json({ json = payload })
end)

App:get("/users/:name/:id", function(c)
    return c.json({
        with_params = c.req:param()
    })
end)

App:get("/users/thomas/oui", function(c)
    return c.json({
        without_params = c.req:param()
    })
end)

App:start()
