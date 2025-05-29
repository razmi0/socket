local socket = require("socket")

---@class ServerConfig
---@field host string
---@field port number

---@class Server
---@field _host string The host address to bind the server to
---@field _port number The port number to bind the server to
---@field _app App The application instance
---@field new fun(app : App): Server  The server instance
---@field start fun(self: Server, base: table): nil Start the HTTP server and begin listening for connections

local Server = {}
Server.__index = Server

---@param app App
function Server.new(app)
    local instance = setmetatable({}, Server)
    instance._host = arg[1] or "127.0.0.1"
    instance._port = tonumber(arg[2]) or 8080
    instance._app = app
    return instance
end

local function close(client)
    if client then
        client:close()
    end
end

local function main(server, app)
    while true do
        -- Blocking I/O: The program waits until the operation completes.
        local client, err = server:accept()
        -- Timeouts: Prevents the program from hanging indefinitely by limiting how long an I/O operation can wait.
        client:settimeout(5)
        if not client then
            goto continue
        end
        -- Run the app
        app:_run(client)
        close(client)
        ::continue::
    end
end

---@param server_config? ServerConfig
function Server:start(server_config)
    if server_config then
        self._host = server_config.host or self._host
        self._port = server_config.port or self._port
    end
    local server = assert(socket.bind(self._host, self._port), "Failed to bind server!")
    print("\27[90m[Started]\27[0m \27[34m" .. "http://" .. self._host .. ":" .. self._port .. "\27[0m")
    main(server, self._app)
end

return Server
