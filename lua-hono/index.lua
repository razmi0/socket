local Server = require("lib/server")
local app = require("lib/app").new()

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


-- Registering static files
--
app:get("/", function(c)
    return c:serve({ path = "./index.html" })
end)

app:get("/index.js", function(c)
    return c:serve({ path = "./public/index.js" })
end)

app:get("/index.css", function(c)
    return c:serve({ path = "./public/index.css" })
end)

app:get("/index.css", function(c)
    return c:serve({ path = "./public/index.css" })
end)

app:use("/any", function(c, next)
    c:header("MyHeader1", "MyHeader1")
    print("-1")
    next()
    print("-2")
end)


app:use("/any", function(c, next)
    c:header("MyHeader2", "MyHeader2")
    print("--3")
    next()
    print("--4")
end)

app:get("/any",
    function(c)
        print("---handler")
        return c:json({
            get = "ok2"
        })
    end
)

Server.new(app):start({
    port = 3000
})
