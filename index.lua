local App = require("lib/server")

local app = App.new()

local payload = {
    some_object = {
        foo = "bar"
    },
    some_array = { "foo", "bar", "baz" }
}

app:get("/", function(c)
    return c:static({ path = "./index.html" })
end)

app:get("/index.js", function(c)
    return c:static({ path = "./public/index.js" })
end)

app:get("/index.css", function(c)
    return c:static({ path = "./public/index.css" })
end)



app:get("/query", function(c)
    local query = c.req:query()
    return c:json({ query = query })
end)

app:get("/json", function(c)
    return c:json({ json = payload })
end)

app:get("/users/:name/:id", function(c)
    return c:json({
        with_params = c.req:param()
    })
end)

app:get("/users/thomas/oui", function(c)
    return c:json({
        without_params = c.req:param()
    })
end)


app:start({
    verbose = true
})
