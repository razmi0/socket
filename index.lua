local App = require("lib/server")


local test_payload = {
    some_object = {
        foo = "bar"
    },
    some_array = { "foo", "bar", "baz" }
}

--:use("/*", function(c)
--  return c:serve({ root = "./static" })
--end)

App.new()
    :get("/", function(c)
        return c:serve({ path = "./index.html" })
    end)

    :get("/index.js", function(c)
        return c:serve({ path = "./public/index.js" })
    end)
    :get("/index.css", function(c)
        return c:serve({ path = "./public/index.css" })
    end)
    :get("/query", function(c)
        local query = c.req:query()
        return c:json({ query = query })
    end)
    :get("/json", function(c)
        return c:json({ json = test_payload })
    end)
    :get("/users/:name/:id", function(c)
        return c:json({
            with_params = c.req:param()
        })
    end)
    :get("/users/thomas/oui", function(c)
        return c:json({
            without_params = c.req:param()
        })
    end)
    :start({ verbose = true })
