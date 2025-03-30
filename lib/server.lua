local socket = require("socket")
local Inspect = require("lib/utils")
local Request = require("lib/request")
local Response = require("lib/response")
local Context = require("lib/context")
local Routes = require("lib/routes")

local log = Inspect.new({ trace = false })

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
    log:push("Creating new App")
    local instance = setmetatable({}, App)
    instance._host = arg[1] or "127.0.0.1"
    instance._port = tonumber(arg[2]) or 8080
    instance._routes = Routes.new()
    return instance
end

function App:get(path, callback)
    log:push("Registering GET " .. path)
    self._routes:_add_route("GET", path, callback)
end

function App:post(path, callback)
    log:push("Registering POST " .. path)
    self._routes:_add_route("POST", path, callback)
end

---@class ServerConfig
---@field host?  string
---@field port? number
---@field verbose? boolean

---@param server_config? ServerConfig
function App:start(server_config)
    log:push("Starting server")
    if server_config then
        self._host = server_config.host or self._host
        self._port = server_config.port or self._port
        local verbose = server_config.verbose ~= nil and server_config.verbose or false
        log:setVerbose(verbose)
    end
    local server = assert(socket.bind(self._host, self._port), "Failed to bind server!")
    local ip, port = server:getsockname()
    -- print("Listening on http://" .. ip .. ":" .. port)

    log:push("Starting loop server : " .. ip .. ":" .. port)
    log:print()
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

        log:push("Accepted client")


        local req_ok, success, result = pcall(function()
            local req = Request.new(client, log)
            local res = Response.new(client, log)
            local ctx = Context.new(req, res)




            if not req or not res or not ctx then
                log:push("Failed to initialize !")
                res:setStatus(400)
                res:send()
            end

            local ok = req:_parse()
            if not ok then
                log:push("Failed to parse request !")
                res:setStatus(400)
                res:send()
                return
            end

            -- Find the route handler
            local route_handler = self._routes:find(req)
            if route_handler then
                log:push("Found route handler")
                local handler_ok, handler_err = pcall(route_handler, ctx)
                if not handler_ok then
                    log:push("Handler error: " .. handler_err)
                    Response.new(client):setStatus(500):send()
                else
                    log:push("Sending response")
                    res:send()
                end
            else
                log:push("No route handler found")
                Response.new(client):setStatus(404):send()
            end


            return true
        end)

        if not req_ok then
            log:push("Server failed !")
            Response.new(client):setStatus(500):send()
        end


        self:_close(client)

        log:print()
        ::continue::
    end
end

function App:_close(client)
    if client then
        log:push("Closing client")
        client:close()
    else
        log:push("Client is nil")
    end
end

return App
