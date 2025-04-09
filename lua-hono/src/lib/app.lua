local inspect = require("inspect")
local Request = require("lib/request")
local Response = require("lib/response")
local Context = require("lib/context")
local Router = require("lib/router")

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

---@param cleanKey? string
function App:see_routes(cleanKey)
    local function clean(node)
        if cleanKey then
            node[cleanKey] = nil
        end
        if node.param then
            for _, child in pairs(node.param) do
                clean(child)
            end
        end
        if node.static then
            for _, child in pairs(node.static) do
                clean(child)
            end
        end
    end

    local printable = self._router.routes
    for method, _ in pairs(printable) do
        clean(printable[method])
    end

    print(inspect(printable))
end

function App:use(path, ...)
    local middlewares = { ... }
    self._router:_add_route("USE", path, middlewares)
    return self
end

function App:get(path, ...)
    local handlers = { ... }
    self._router:_add_route("GET", path, handlers)
    return self
end

function App:post(path, ...)
    local handlers = { ... }
    self._router:_add_route("POST", path, handlers)
    return self
end

function App:put(path, ...)
    local handlers = { ... }
    self._router:_add_route("PUT", path, handlers)
    return self
end

function App:delete(path, ...)
    local handlers = { ... }
    self._router:_add_route("DELETE", path, handlers)
    return self
end

function App:all(path, ...)
    local handlers = { ... }
    self._router:_add_route("ALL", path, handlers)
    return self
end

---@param err number|string|{[1] : number, [2] : string}
local function err_handler(err)
    local res = Response.new(client)
    if type(err) == "number" then
        res:setStatus(err)
    elseif type(err) == "string" then
        print("Unhandle internal error : " .. err)
        res:setStatus(500)
    elseif type(err) == "table" then
        local code = err[0]
        local err_str = err[1]
        print("Unhandle internal error : " .. err_str)
        res:setStatus(code)
    end
    res:send()
end

function App:_run(client)
    xpcall(
        function()
            local req = Request.new(client)
            local res = Response.new(client)
            local ctx = Context.new(req, res)
            if not req or not res or not ctx then
                error(400)
            end
            local ok = req:_parse()
            if not ok then
                error(400)
            end
            -- Find the route handler in the router no magic
            local handlers, found_path, params = self._router:_match(req.method, req.path)
            -- Reference params in Request & Context ( default/reset to {} )
            req._params = params
            -- Not found case
            if not found_path then
                error(404)
            end
            -- Wrong methods (found path but not handlers)
            if not handlers then
                error(405)
            end
            -- We found a route with user callbacks
            local handler_response = self._router:_run_route(handlers, ctx)
            if not handler_response then
                error({ 500, ctx.req.path .. "Your handler didn't return a response" })
            end
            -- all went well, handler response is sent
            handler_response:send()
        end,
        err_handler
    )
end

return App
