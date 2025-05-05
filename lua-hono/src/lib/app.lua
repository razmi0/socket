local inspect = require("inspect")
local Request = require("lib.request")
local Response = require("lib.response")
local Context = require("lib.context")
local Router = require("lib.router")
local compose = require("lib.compose")


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
    ---@param err { [1] : number, [2] : Context, [3] : string? }
    local function err_handler(err)
        local res = err[2].res
        if err[3] then
            print(err[3])
        end
        res:setContentType("text/plain")
        res:setStatus(err[1])
        res:setBody(tostring(err[1]) .. " " .. res:msgFromCode(err[1]))
        res:send()
    end
    xpcall(
        function()
            local req = Request.new(client)
            local res = Response.new(client)
            local ctx = Context.new(req, res)
            if not req or not res or not ctx then
                error({ 400, ctx })
            end
            local ok = req:_parse()
            if not ok then
                error({ 400, ctx })
            end
            -- Find the route handler in the router no magic
            local handlers, params, matched = self._router:match(req.method, req.path)
            -- Reference params in Request & Context ( default/reset to {} )
            req._params = params
            -- Not found case
            if not matched then
                error({ 404, ctx })
            end
            -- Wrong methods (found path but not handlers)
            if not handlers then
                error({ 405, ctx })
            end
            -- We found a route with user callbacks
            local handler_response = compose(handlers, ctx)
            if not handler_response then
                error({ 500, ctx, "No response has been sent " .. ctx.req.method .. ":" .. ctx.req.path })
            end
            -- all went well, handler response is sent
            handler_response:send()
        end,
        err_handler
    )
end

return App
