local Router = require("lib.router")
local Tx = require("lib.tests.Tx")

print("# Basics Tests")



Tx.describe("static", function()
    Tx.it("should match static route", function()
        local router = Router.new()
        router:add("GET", "/hello", function() return "ok" end)
        local x, p = router:match("GET", "/hello")
        Tx.equal(x[1](), "ok")
        Tx.equal(p, {})
    end)

    Tx.it("should not match unknown route", function()
        local router = Router.new()
        router:add("GET", "/known", function() return 1 end)
        local x, p = router:match("GET", "/unknown")
        Tx.equal(x, nil)
        Tx.equal(p, nil)
    end)

    Tx.it("should match route with trailing slash", function()
        local router = Router.new()
        router:add("GET", "/test", function() return "no slash" end)
        local x, _ = router:match("GET", "/test/")
        Tx.equal(x[1](), "no slash")
    end)

    Tx.it("should match root route", function()
        local router = Router.new()
        router:add("GET", "/", function() return "root" end)
        local x, _ = router:match("GET", "/")
        Tx.equal(x[1](), "root")
    end)
end)

Tx.describe("trie state", function()
    Tx.it("should throw error if inserting route but matcher already built", function()
        local router = Router.new()
        router:add("GET", "/hello", function() return "ok" end)
        local x, p = router:match("GET", "/hello")
        Tx.throws(function()
            router:add("GET", "/hello", function() return "ok" end)
        end)
    end)
end)

Tx.describe("methods", function()
    Tx.it("should return 405 type no handler but found match", function()
        local router = Router.new()
        router:add("GET", "/hello", function() return "hello" end)
        local x, p, match = router:match("POST", "/hello")
        Tx.equal(x, nil)
        Tx.equal(p, nil)
        Tx.equal(match, true)
    end)

    Tx.it("should insert and search all methods", function()
        local methods = { "GET", "POST", "PUT", "PATCH", "HEAD", "OPTIONS", "DELETE" }
        local results = {}
        local x = {}
        local router = Router.new()
        for _, m in ipairs(methods) do
            router:add(m, "/hello", function() return m end)
        end
        for _, m in ipairs(methods) do
            local hs, _ = router:match(m, "/hello")
            table.insert(x, hs[1])
        end
        for _, fn in ipairs(x) do
            table.insert(results, fn())
        end
        Tx.equal(results, methods)
    end)

    Tx.it("should accept and find custom method route", function()
        local router = Router.new()
        router:add("PURGE", "/cache", function() return "purge cache" end)
        local x, p = router:match("PURGE", "/cache")
        Tx.equal(x[1](), "purge cache")
    end)
end)

Tx.describe("params", function()
    Tx.it("should match simple parameter", function()
        local router = Router.new()
        router:add("GET", "/user/:id", function() return 1 end)
        local x, p = router:match("GET", "/user/42")
        Tx.equal(p["id"], "42")
    end)

    Tx.it("should match parameter in middle", function()
        local router = Router.new()
        router:add("GET", "/:lang/docs", function() return 1 end)
        local x, p = router:match("GET", "/en/docs")
        Tx.equal(p["lang"], "en")
    end)

    Tx.it("should match multiple parameters", function()
        local router = Router.new()
        router:add("GET", "/:type/:id", function() return "ok" end)
        local x, p = router:match("GET", "/user/99")
        Tx.equal(p["type"], "user")
        Tx.equal(p["id"], "99")
    end)
end)

Tx.describe("patterns", function()
    Tx.it("should match parameter with pattern", function()
        local router = Router.new()
        router:add("GET", "/file/:id{%d+}", function() return "number" end)
        local x, p = router:match("GET", "/file/123")
        Tx.equal(p["id"], "123")
    end)

    Tx.it("should not match pattern if invalid", function()
        local router = Router.new()
        router:add("GET", "/file/:id{%d+}", function() return "number" end)
        local x, p = router:match("GET", "/file/abc")
        Tx.equal(x, nil)
        Tx.equal(p, nil)
    end)
end)

Tx.describe("optional", function()
    Tx.it("should match optional parameter present", function()
        local router = Router.new()
        router:add("GET", "/page/:id?", function() return "maybe" end)
        local x, p = router:match("GET", "/page/42")
        Tx.equal(p["id"], "42")
    end)

    Tx.it("should match optional parameter missing", function()
        local router = Router.new()
        router:add("GET", "/page/:id?", function() return "maybe" end)
        local x, p = router:match("GET", "/page")
        Tx.equal(p["id"], nil)
    end)

    Tx.it("should match optional parameter with validation", function()
        local router = Router.new()
        router:add("GET", "/doc/:slug?{%a+}", function() return "slug" end)
        local x, p = router:match("GET", "/doc/hello")
        Tx.equal(p["slug"], "hello")
    end)

    Tx.it("should not match optional parameter if fails pattern", function()
        local router = Router.new()
        router:add("GET", "/doc/:slug?{%a+}", function() return "slug" end)
        local x, p = router:match("GET", "/doc/123")
        Tx.equal(x, nil)
    end)
end)

Tx.describe("wildcards", function()
    Tx.it("should match wildcard segment", function()
        local router = Router.new()
        router:add("GET", "/path/*", function() return "wild" end)
        local x, p = router:match("GET", "/path/anything/here")
        Tx.equal(x[1](), "wild")
        Tx.equal(p["*"], "anything/here")
    end)

    Tx.it("should not match empty wildcard segment", function()
        local router = Router.new()
        router:add("GET", "/path/*", function() return "wild" end)
        local x, p = router:match("GET", "/path")
        Tx.equal(x, nil)
        Tx.equal(p, nil)
    end)

    Tx.it("should not match if wildcard is not at end", function()
        local router = Router.new()
        router:add("GET", "/path/*/edit", function() return "invalid" end)
        local x, p = router:match("GET", "/path/something/edit")
        Tx.equal(x, nil)
    end)
end)

Tx.describe("priority", function()
    Tx.it("should prefer static over param", function()
        local router = Router.new()
        router:add("GET", "/user/me", function() return "me" end)
        router:add("GET", "/user/:id", function() return "id" end)
        local x, _ = router:match("GET", "/user/me")
        Tx.equal(x[1](), "me")
    end)

    Tx.it("should not match static instead of param", function()
        local router = Router.new()
        router:add("GET", "/static/path", function() return 1 end)
        local x, p = router:match("GET", "/:type/path")
        Tx.equal(x, nil)
    end)

    Tx.it("should prefer static over wildcard", function()
        local router = Router.new()
        router:add("GET", "/path/known", function() return "known" end)
        router:add("GET", "/path/*", function() return "wild" end)
        local x, p = router:match("GET", "/path/known")
        Tx.equal(x[1](), "known")
    end)

    Tx.it("should choose best scored/specific route", function()
        local router = Router.new()
        router:add("GET", "/user/:1", function() return 1 end)
        router:add("GET", "/user/:1/:2", function() return 2 end)
        router:add("GET", "/user/:1/:2/:3", function() return 3 end)
        local x, p = router:match("GET", "/user/p1/p2")
        Tx.equal({ x[1](), p["2"] }, { 2, "p2" })
    end)
end)
