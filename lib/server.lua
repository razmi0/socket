local socket = require("socket")
local inspect = require("lib/utils")
local Request = require("lib/request")
local Response = require("lib/response")
local Context = require("lib/context")
local Routes = require("lib/routes")

---@class App
---@field _host string The host address to bind the server to
---@field _port number The port number to bind the server to
---@field _routes Routes The routing table containing GET and POST route handlers
---@field start fun(self: App, base: table): nil Start the HTTP server and begin listening for connections
---@field get fun(self: App, path: string, callback: function): nil Register a GET route handler
---@field post fun(self: App, path: string, callback: function): nil Register a POST route handler
---@field put fun(self: App, path: string, callback: function): nil Register a PUT route handler

local App = {}
App.__index = App

function App.new()
    local instance = setmetatable({}, App)
    instance._host = arg[1] or "127.0.0.1"
    instance._port = tonumber(arg[2]) or 8080
    instance._routes = Routes.new()
    return instance
end

function App:get(path, callback)
    self._routes:_add_route("GET", path, callback)
end

function App:post(path, callback)
    self._routes:_add_route("POST", path, callback)
end

function App:start(server_config)
    if server_config then
        self._host = server_config.host or self._host
        self._port = server_config.port or self._port
    end
    local server = assert(socket.bind(self._host, self._port), "Failed to bind server!")
    local ip, port = server:getsockname()
    print("Listening on http://" .. ip .. ":" .. port)

    self:_loop(server)
end

function App:_loop(server)
    while true do
        -- Blocking I/O: The program waits until the operation completes (e.g., waiting for a network response).
        local client, err = server:accept()
        --Timeouts: Prevents the program from hanging indefinitely by limiting how long an I/O operation can wait.
        client:settimeout(5)


        -- Handle accept errors
        if not client then
            print("server:accept() error:", err)
            goto continue
        end


        local req_ok, res_ok = pcall(function()
            local req = Request.new(client)
            local res = Response.new(client)
            local ctx = Context.new(req, res)




            if not req or not res or not ctx then
                print("Failed to initialize !")
                res:setStatus(400)
                res:send()
            end

            local ok = req:_parse()
            if not ok then
                print("Failed to parse request !")
                res:setStatus(400)
                res:send()
                return
            end

            -- Find the route handler
            local route_handler = self._routes:find(req)
            if route_handler then
                local handler_ok, handler_err = pcall(route_handler, ctx)
                if not handler_ok then
                    print("Handler error:", handler_err)
                    Response.new(client):setStatus(500):send()
                else
                    res:send()
                end
            else
                -- Handle not found
                Response.new(client):setStatus(404):send()
            end




            return true
        end)

        if not req_ok then
            print("Server failed :: ", res_ok)
            Response.new(client):setStatus(500):send()
            -- print("-->", tostring(500))
        else
            -- print("-->", tostring(200))
        end


        self:_close(client)
        ::continue::
    end
end

function App:_close(client)
    if client then
        print("closing client")
        client:close()
    else
        print("client is nil")
    end
end

return App
