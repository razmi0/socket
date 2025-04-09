local Server = require("lib/server")
local app = require("lib/app").new()
local logger = require("lib/middleware/logger")

local function heavy_computation(size)
    local numbers = {}
    for i = 1, size do
        table.insert(numbers, i)
    end
    local transformed = {}
    for _, n in ipairs(numbers) do
        table.insert(transformed, math.sqrt(n) * (n ^ 1.5) - math.log(n + 1))
    end
    local filtered = {}
    for _, n in ipairs(transformed) do
        if n % 2 ~= 0 then
            table.insert(filtered, n)
        end
    end
    local sum = 0
    for _, val in ipairs(filtered) do
        sum = sum + val
    end
    return sum
end




--#region Registering static files
--
-- app
--     :get("/", function(c)
--         return c:serve({ path = "./index.html" })
--     end)
--     :get("/index.js", function(c)
--         return c:serve({ path = "./public/index.js" })
--     end)
--     :get("/index.css", function(c)
--         return c:serve({ path = "./public/index.css" })
--     end)
--     :get("/luvit.webp", function(c)
--         return c:serve({ path = "./public/luvit.webp" })
--     end)
--#endregion

------ not works ----
-- app:use("*", logger())
------

------ works ----

-- app:use("/me", function(c, next)
--     print("1" .. c.req.path)
--     next()
--     print("4" .. c.req.path)
-- end)

app:use("/me", logger())

-- app:get("/me", function(c)
--     return c:text(c.req.path .. "2")
-- end) -- 200


-----


-- app:use("*/*", function(c) print("ALWAYS THERE 2 " .. c.req.path) end) -- 404 expected

-- app:get("/me/you", function(c) return c:html(c.req.path) end)          -- 200 expected

-- app:get("/me/you/us", function(c) return c:html(c.req.path) end)       -- 200 expected

-- app:get("/no-response", function(c) print("this route does not send a response") end)


-- app:see_routes()
Server.new(app):start()
