local Request = require("lib/request")
local Response = require("lib/response")
local Context = require("lib/context")
local Router = require("lib/router")


---@class App
---@field _log table
---@field _router Router
---@field get fun(self: App, path: string, callback: function): App
---@field post fun(self: App, path: string, callback: function): App
---@field new fun(self: App): App
---@field _setLogger fun(self: App, log: table): nil
---@field _run fun(self: App, client: Client): nil
---@field use fun(self: App, middleware: function): App

local App = {}
App.__index = App

function App.new()
    local instance = setmetatable({}, App)
    instance._router = Router.new()
    return instance
end

function App:_setLogger(log)
    self._log = log
end

-- See the routes in json format
function App:see_routes()
    if not self._log then
        return
    end
    self._log:routes(self._router)
end

function App:use(middleware)
    if middleware.identity == "logger" then
        self:_setLogger(middleware.handler)
    elseif type(middleware.handler) == "function" then
        local x = pcall(middleware.handler, next)
    end

    return self
end

function App:get(path, ...)
    local handlers = { ... }
    self._router:_register("GET", path, handlers)
    return self
end

function App:post(path, ...)
    local handlers = { ... }
    self._router:_register("POST", path, handlers)
    return self
end

function App:put(path, ...)
    local handlers = { ... }
    self._router:_register("PUT", path, handlers)
    return self
end

function App:delete(path, ...)
    local handlers = { ... }
    self._router:_register("DELETE", path, handlers)
    return self
end

function App:_run(client)
    local req_ok, res_err = pcall(function()
        local req = Request.new(client, self._log)
        local res = Response.new(client, self._log)
        local ctx = Context.new(req, res)

        if not req or not res or not ctx then
            if self._log then
                self._log:push("Failed to initialize !")
            end
            res:setStatus(400)
            res:send()
            return
        end

        local ok = req:_parse()
        if not ok then
            if self._log then
                self._log:push("Failed to parse request !")
            end
            res:setStatus(400)
            res:send()
            return
        end


        -- Find the route handler
        local handlers, found_path, params = self._router:_match(req.method, req.path)

        -- Reference params in Request & Context ( default/reset to {} )
        req._params = params

        -- Not found case
        if not found_path then
            if self._log then
                self._log:push("Not found", { is_err = true })
            end
            res:setStatus(404)
            res:send()
            return
        end

        -- Wrong methods (found path but not handlers)
        if not handlers then
            if self._log then
                self._log:push("Method not allowed", { is_err = true })
            end
            res:setStatus(405)
            res:send()
            return
        end

        -- We found a route with user callbacks
        if self._log then
            self._log:push("Found route")
        end


        local handler_response = self._router:_run_route(handlers, ctx)


        if not handler_response then
            if self._log then
                self._log:push(handler_response, { is_err = true, prefix = "Handler error" })
            end
            Response.new(client):setStatus(500):send()
        else
            if self._log then
                self._log:push("Sending response")
            end
            handler_response:send()
        end
    end)

    if not req_ok then
        if self._log then
            self._log:push(res_err, { is_err = true, prefix = "Server error" })
        end
        Response.new(client):setStatus(500):send()
    end

    -- if self._log then
    --     self._log:push(self._router._routes)
    -- end
end

return App
