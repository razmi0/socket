local Request = require("lib/request")
local Response = require("lib/response")
local Context = require("lib/context")
local Routes = require("lib/routes")


---@class App
---@field _log Inspect
---@field _routes Routes
---@field get fun(self: App, path: string, callback: function): App
---@field post fun(self: App, path: string, callback: function): App
---@field new fun(self: App): App
---@field _setLogger fun(self: App, log: Inspect): nil
---@field _run fun(self: App, client: Client): nil
---@field use fun(self: App, middleware: function): App

local App = {}
App.__index = App

function App.new()
    local instance = setmetatable({}, App)
    instance._routes = Routes.new()
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
    self._log:routes(self._routes)
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
    self._routes:_add_route("GET", path, handlers)
    return self
end

function App:post(path, ...)
    local handlers = { ... }
    self._routes:_add_route("POST", path, handlers)
    return self
end

function App:put(path, ...)
    local handlers = { ... }
    self._routes:_add_route("PUT", path, handlers)
    return self
end

function App:delete(path, ...)
    local handlers = { ... }
    self._routes:_add_route("DELETE", path, handlers)
    return self
end

function App:_run(client)
    local req_ok, res_err = pcall(function()
        local req = Request.new(client, self._log)
        local res = Response.new(client, self._log)
        local ctx = Context.new(req, res)

        if not req or not res or not ctx then
            self._log:push("Failed to initialize !")
            res:setStatus(400)
            res:send()
        end

        local ok = req:_parse()
        if not ok then
            self._log:push("Failed to parse request !")
            res:setStatus(400)
            res:send()
            return
        end


        -- Find the route handler
        local route_handlers = self._routes:find(req)
        if route_handlers then
            self._log:push("Found route")
            local handler_response = self._routes:_run_chain(route_handlers, ctx)
            if not handler_response then
                self._log:push(handler_response, { is_err = true, prefix = "Handler error" })
                Response.new(client):setStatus(500):send()
            else
                self._log:push("Sending response")
                handler_response:send()
            end
        else
            self._log:push("No route handler found", { is_err = true, prefix = "Route error" })
            Response.new(client):setStatus(404):send()
        end
    end)

    if not req_ok then
        self._log:push(res_err, { is_err = true, prefix = "Server error" })
        Response.new(client):setStatus(500):send()
    end
end

return App


-- {
--     indexed = {
--       ["/"] = { "<function 1>" },
--       ["/chain"] = { "<function 2>", "<function 3>", "<function 4>" },
--       ["/index.css"] = { "<function 5>" },
--       ["/index.js"] = { "<function 6>" },
--       ["/json"] = { "<function 7>" },
--       ["/query"] = { "<function 8>" },
--       ["/users/thomas/oui"] = { "<function 9>"
--     }
-- }
