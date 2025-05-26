local inspect = require("inspect")
local Request = require("lib.request")
local Response = require("lib.response")
local Context = require("lib.context")
local Router = require("lib.router")
local compose = require("lib.compose")
local HTTP400 = require("lib.http-exception.bad-request")
local HTTP404 = require("lib.http-exception.not-found")
local HTTP405 = require("lib.http-exception.method-not-allowed")
local HTTP500 = require("lib.http-exception.internal-server-error")


---@class App
---@field _router Router
---@field new fun():App
---@field get fun(self: App, path: string, callback: function): App
---@field post fun(self: App, path: string, callback: function): App
---@field _run fun(self: App, client: unknown): nil
---@field use fun(self: App, middleware: function): App

local App = {}
App.__index = App

function App.new()
    local instance = setmetatable({}, App)
    instance._router = Router.new()
    return instance
end

function App:use(path, ...)
    local middlewares = { ... }
    self._router:add("USE", path, middlewares)
    return self
end

function App:get(path, ...)
    local handlers = { ... }
    self._router:add("GET", path, handlers)
    return self
end

function App:post(path, ...)
    local handlers = { ... }
    self._router:add("POST", path, handlers)
    return self
end

function App:put(path, ...)
    local handlers = { ... }
    self._router:add("PUT", path, handlers)
    return self
end

function App:delete(path, ...)
    local handlers = { ... }
    self._router:add("DELETE", path, handlers)
    return self
end

function App:all(path, ...)
    local handlers = { ... }
    self._router:add("ALL", path, handlers)
    return self
end

function App:_run(client)
    local req, res = Request.new(client), Response.new(client)
    local ctx = Context.new(req, res)
    local err_handler = HTTP404

    if not req or not res or not ctx then err_handler = HTTP500 end
    local ok = req:_parse()
    if not ok then err_handler = HTTP400 end

    local mws, params = self._router:match(req.method, req.path)
    req._params = params
    local x = compose(handlers, ctx)

    print(inspect(mws))
    print("x : ", inspect(x))

    -- if err_handler then
    --     handlers[#handlers + 1] = err_handler
    --     local handler_response = compose(handlers, ctx)
    --     handler_response:send()
    --     return
    -- end


    -- if matched and not matchMethod then
    --     handlers[#handlers + 1] = HTTP405
    --     local handler_response = compose(handlers, ctx)
    --     handler_response:send()
    -- end

    -- if not matched and not matchMethod then
    --     handlers[#handlers + 1] = HTTP404
    --     local handler_response = compose(handlers, ctx)
    --     handler_response:send()
    -- end

    local response = err_handler(ctx)
    response:send()
end

return App
