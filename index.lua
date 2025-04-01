local Server = require("lib/server")
local App = require("lib/app")
local logger = require("lib/logger")

local test_payload = {
    some_object = {
        foo = "bar"
    },
    some_array = { "foo", "bar", "baz" }
}

local app = App.new()

-- Registering logger middleware
app:use(logger({ trace = false, verbose = true }))

-- Registering static files
app
    :get("/", function(c)
        return c:serve({ path = "./index.html" })
    end)
    :get("/index.js", function(c)
        return c:serve({ path = "./public/index.js" })
    end)
    :get("/index.css", function(c)
        return c:serve({ path = "./public/index.css" })
    end)

-- Registering query handler
app:get("/query", function(c)
    local query = c.req:query()
    return c:json({ query = query })
end)

-- Registering json handler
app:get("/json", function(c)
    return c:json({ json = test_payload })
end)

-- Registering path with params
app:get("/users/:name/:id", function(c)
    return c:json({
        with_params = c.req:param()
    })
end)

-- Registering path that conflict with the previous one
-- Declared as a litteral string, it has a priority over the previous one ( IndexedRouter )
app:get("/users/thomas/oui", function(c)
    return c:json({
        without_params = c.req:param()
    })
end)

-- Registering a route with a chain of callbacks Array<[...Middleware[], Handler]>
app:get("/chain",
    -- Middleware 1
    function(c, next)
        c:set("key-1", " wo")
        next()
        c:header(c:get("handler-1"), "done")
    end,
    -- Middleware 2
    function(c, next)
        c:set("key-2", "rld")
        next()
        c:header(c:get("handler-2"), "done")
    end,
    -- Handler
    function(c)
        c:set("handler-1", "X-Middleware-1")
        c:set("handler-2", "X-Middleware-2")
        return c:text("Hello" .. c:get("key-1") .. c:get("key-2")) -- Hello world
    end
)

app:see_routes()

Server.new(app):start()
