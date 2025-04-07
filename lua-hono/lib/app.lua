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

-- See the routes in json format
---@param config? table
function App:see_routes(config)
    local function clean_order(node)
        node.__order = nil

        if node.param then
            for _, child in pairs(node.param) do
                clean_order(child)
            end
        end

        if node.static then
            for _, child in pairs(node.static) do
                clean_order(child)
            end
        end
    end

    local printable = self._router.routes
    if config and config.order == false then
        for method, _ in pairs(printable) do
            clean_order(printable[method])
        end
    end
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

function App:_run(client)
    ---@param err number
    local function err_handler(err)
        local res = Response.new(client)
        if err == 400 then
            res:setStatus(err)
            res:send()
        elseif err == 404 then
            res:setStatus(err)
            res:send()
        elseif err == 405 then
            res:setStatus(err)
            res:send()
        else
            if type(err) == "string" then
                print("Unhandle internal error : " .. err)
            end
            res:setStatus(500)
            res:send()
        end
    end

    xpcall(function()
        local req = Request.new(client)
        local res = Response.new(client)
        local ctx = Context.new(req, res)
        if not req or not res or not ctx then
            error(400)
        end
        local ok = req:parse()
        if not ok then
            error(400)
        end
        -- Find the route handler
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
            error(500)
        end
        -- all went well, handler response is sent
        handler_response:send()
    end, err_handler)
end

return App
