local App = require("lib/server")

local data = {
    message = "Hello, World!",
    some_object = {
        foo = "bar"
    },
    some_array = {"foo", "bar", "baz"}
}

App:get("/html", function(c)
    return c.html("<h1>Hello, World!</h1>")
end)

App:get("/json", function(c)
    return c.json(data)
end)

App:post("/", function(c)
    return c.json(data)
end)

App:start({
    port = 8080
})
