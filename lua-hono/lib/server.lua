-- to much things in app class, need to split it, especially route execution

local socket = require("socket")


local function close(client, logger)
    if client then
        if logger then
            logger:push("Closing client")
        end
        client:close()
    else
        if logger then
            logger:push("Client is nil")
        end
    end
end


local function main(server, app)
    -- Starting loop

    local logger = app._log

    while true do
        --
        -- Blocking I/O: The program waits until the operation completes (e.g., waiting for a network response).
        local client, err = server:accept()

        --Timeouts: Prevents the program from hanging indefinitely by limiting how long an I/O operation can wait.
        client:settimeout(5)

        -- Handle accept errors
        if not client then
            if logger then
                logger:push("server:accept() error:", err, true)
            end
            goto continue
        end

        if logger then
            logger:push("Accepted client")
        end

        -- Run the app
        app:_run(client)

        -- Close the client
        close(client, logger)

        if logger then
            logger:print()
        end

        ::continue::
    end
end


---@class Server
---@field _host string The host address to bind the server to
---@field _port number The port number to bind the server to
---@field start fun(self: Server, base: table): nil Start the HTTP server and begin listening for connections
---@field new fun(app : App):Server  The server instance
---@field _app App The application instance

local Server = {}
Server.__index = Server

---@param app App
function Server.new(app)
    local instance = setmetatable({}, Server)
    if app._log then
        instance._log = app._log
    end
    instance._host = arg[1] or "127.0.0.1"
    instance._port = tonumber(arg[2]) or 8080
    instance._app = app
    return instance
end

---@class ServerConfig
---@field host?  string
---@field port? number
---@field verbose? boolean
---@param server_config? ServerConfig
function Server:start(server_config)
    if server_config then
        self._host = server_config.host or self._host
        self._port = server_config.port or self._port
    end
    local server = assert(socket.bind(self._host, self._port), "Failed to bind server!")
    local ip, port = server:getsockname()

    if self._log then
        self._log:push("Starting loop server : " .. ip .. ":" .. port)
        self._log:print()
    end

    if not self._log then
        print("\27[37mLuaSocket server listening : \27[0m" .. ip .. ":" .. port)
    end


    -- Starting loop

    main(server, self._app)

    -- while true do
    --     --
    --     -- Blocking I/O: The program waits until the operation completes (e.g., waiting for a network response).
    --     local client, err = server:accept()

    --     --Timeouts: Prevents the program from hanging indefinitely by limiting how long an I/O operation can wait.
    --     client:settimeout(5)

    --     -- Handle accept errors
    --     if not client then
    --         self:log("server:accept() error:", err, true)
    --         goto continue
    --     end

    --     if self._log then
    --         self._log:push("Accepted client")
    --     end

    --     -- Run the app
    --     self._app:_run(client)

    --     -- Close the client
    --     self:_close(client)

    --     if self._log then
    --         self._log:print()
    --     end

    --     ::continue::
    -- end
end

return Server
