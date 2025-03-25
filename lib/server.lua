---@class App
---@field _host string The host address to bind the server to
---@field _port number The port number to bind the server to
---@field _server table The socket server instance
---@field _request Request The request handler instance
---@field _response Response The response handler instance
---@field _routes table The routing table containing GET and POST route handlers
---@field start fun(self: App, base: table): nil Start the HTTP server and begin listening for connections
---@field get fun(self: App, path: string, callback: function): nil Register a GET route handler
---@field post fun(self: App, path: string, callback: function): nil Register a POST route handler
local socket = require("socket")
local Request = require("lib/request")
local Response = require("lib/response")
local inspector = require("inspect")

local inspect = function(msg, obj)
    print(msg, inspector(obj))
end

local App = {
    -- Protected properties
    _host = "localhost",
    _port = 0,
    _server = nil,
    _request = Request,
    _response = Response,
    _routes = {
        GET = {},
        POST = {},
        ---Find a route handler based on the current request method and path
        ---@return function|nil The route handler function if found, nil otherwise
        find = function(self)
            return self._routes[self._request.method][self._request.path]
        end
    },

    -- Public methods
    ---Start the HTTP server and begin listening for connections
    ---@param base table Configuration table containing host and port
    ---@field base.host string|nil Optional host address to bind to (defaults to _host)
    ---@field base.port number|nil Optional port number to bind to (defaults to _port)
    start = function(self, base)
        local host = base.host or self._host
        local port = base.port or self._port

        self._server = assert(socket.bind(host, port), "Failed to bind server!")
        print("listening on http://" .. host .. ":" .. port)

        while true do
            local client = self._server:accept()
            client:settimeout(0.5)

            -- bad dependency injection
            self._request:_build(client)
            self._response:_bind(client)

            -- Find route => User callback() --
            local route = self._routes.find(self)

            local c = {
                req = self._request,
                res = self._response,
                header = function(key, value)
                    return self._response:addHeader(key, value)
                end,
                body = function(body)
                    self._response:setBody(body)
                end,
                status = function(status)
                    self._response:setStatus(status)
                end
            }

            local void = route(c)

            client:close()

            -- Print some debug info
            print("<--", self._request.method, self._request.path)
            print("-->", self._response.status, self._response:header("Content-Type"))
        end
    end,

    ---Register a GET route handler
    ---@param path string The URL path to handle
    ---@param callback function The callback function to handle the route
    get = function(self, path, callback)
        self._routes.GET[path] = callback
    end,

    ---Register a POST route handler
    ---@param path string The URL path to handle
    ---@param callback function The callback function to handle the route
    post = function(self, path, callback)
        self._routes.POST[path] = callback
    end

}

return App
