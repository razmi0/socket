local inspect = require("inspect")
local Request = require("lib.request")
local Response = require("lib.response")
local Context = require("lib.context")
local Router = require("lib.router")
local compose = require("lib.compose")
local HTTP400 = require("lib.http-exception.bad-request")
local HTTP500 = require("lib.http-exception.internal-server-error")

---@class App
---@field _router Router
---@field new fun():App
---@field use fun(self: App, middleware: function): App
---@field get fun(self: App, path: string, callback: function): App
---@field post fun(self: App, path: string, callback: function): App
---@field put fun(self: App, path: string, callback: function): App
---@field delete fun(self: App, path: string, callback: function): App
---@field all fun(self: App, path: string, callback: function): App
---@field _run fun(self: App, client: any): nil

local App = {}
App.__index = App

function App.new()
    local instance = setmetatable({}, App)
    instance._router = Router.new()
    return instance
end

function App:use(path, ...)
    local middlewares = { ... }
    self._router:add(nil, path, middlewares)
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
    for _, m in ipairs({ "POST", "GET", "PUT", "DELETE", "PATCH" }) do
        self._router:add(m, path, handlers)
    end
    return self
end

function App:on(methods, paths, ...)
    local handlers = { ... }

    methods =
        type(methods) == "string" and { methods }
        or methods
        or { "POST", "GET", "PUT", "DELETE", "PATCH" }
    paths =
        type(paths) == "string" and { paths }
        or paths
        or { "/" }

    for _, m in ipairs(methods) do
        for _, p in ipairs(paths) do
            self._router:add(m, p, handlers)
        end
    end
end

function App:_run(client)
    local req, res = Request.new(client), Response.new(client)
    local ctx = Context.new(req, res)

    if not req or not res or not ctx then ctx._err_handler = HTTP500 end
    if not req:_parse() then ctx._err_handler = HTTP400 end

    local mws, params, match = self._router:match(req.method, req.path)
    req._params = params
    compose(mws, ctx, match)
    if ctx._finalized then
        ctx.res:send()
    else
        print()
        HTTP500(ctx):send()
    end
end

return App
