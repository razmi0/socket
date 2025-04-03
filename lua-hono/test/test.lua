local inspect = require("inspect")
local Response = require("lib.response")

-- local App = {}
-- App.__index = App

-- function App.new()
--     local self = setmetatable({}, App)
--     return self
-- end

-- function App:get(path, ...)
--     local handlers = { ... }

--     for i, handler in ipairs(handlers) do
--         print(i .. " : " .. handler())
--     end
-- end

-- local app = App.new()
-- app:get("/", function()
--     return "Hello, World!"
-- end, function()
--     return "Hello, World!"
-- end
-- )
local function printTable(tbl, indent)
    if tbl == nil then
        print("tbl is nil")
        return
    end
    if type(tbl) == "string" then
        print(tbl)
        return
    end
    if type(tbl) == "boolean" then
        print(tostring(tbl))
        return
    end
    indent = indent or 0
    local formatting = string.rep("  ", indent)
    for key, value in pairs(tbl) do
        if type(value) == "table" then
            print(formatting .. tostring(key) .. ":")
            printTable(value, indent + 1)
        else
            print(formatting .. tostring(key) .. ": " .. tostring(value))
        end
    end
end

-- Global variable to capture the final result.
-- local res = nil
-- runChain executes a list of middleware functions followed by a final handler.
-- chain: an array of middleware functions
-- context: the context object passed to each function
-- handler: the final function to execute after middleware
local function runChain(chain, context)
    local handler = chain[#chain]
    local response = nil

    local function dispatch(i)
        -- all middleware and handler are executed, we leave the execution flow
        if i > #chain then return end

        -- Execute final handler and store the response
        if i == #chain then
            response = handler(context)
        else
            -- Middleware execution with next control
            local nextCalled = false
            local function next()
                if not nextCalled then
                    nextCalled = true
                    dispatch(i + 1)
                end
            end

            -- Execute middleware and ignore its return value
            chain[i](context, next)
        end
    end

    dispatch(1)
    return response
end

-- Example usage:
local context = {
    res = Response.new({})
}

local chain = {
    function(c, next)
        print("middleware start 1")
        table.insert(c, "middleware 1")
        next()
        print("middleware end 1")
    end,
    function(c, next)
        print("middleware start 2")
        table.insert(c, "middleware 2")
        next()
        print("middleware end 2")
    end,
    function(c, next)
        print("middleware start 3")
        table.insert(c, "middleware 3")
        next()
        print("middleware end 3")
        c.res:setStatus(404)
    end,
    function(c)
        print("handler")
        table.insert(c, "handler")
        return c.res
    end
}

-- Execute the chain.
local returned = runChain(chain, context)

if returned == nil then
    print("returned is nil")
end

printTable(returned)
