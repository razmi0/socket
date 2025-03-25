local socket = require("socket")
local Request = require("lib/request")
local Response = require("lib/response")
local inspector = require("inspect")
local cjson = require "cjson"

local inspect = function(msg, obj)
    print(msg, inspector(obj))
end

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
local App = {
    __client = nil,
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

    _createContext = function(self)
        return {
            req = self._request,
            res = self._response,
            -- Add a header to the response
            -- @param key string The header key
            -- @param value string The header value
            header = function(key, value)
                self._response:addHeader(key, value)
                return self._response
            end,
            -- Set the body of the response
            -- @param body string The body of the response
            -- @param status number|nil The status code of the response
            -- @param headers table|nil The headers of the response
            body = function(body, status, headers)
                self._response:setBody(body)
                if status then
                    self._response:setStatus(status)
                end
                if headers then
                    for key, value in pairs(headers) do
                        self._response:addHeader(key, value)
                    end
                end
                return self._response
            end,

            text = function(text)
                self._response:setStatus(200)
                self._response:setBody(text)
                self._response:addHeader("Content-Type", "text/plain")
                return self._response
            end,

            json = function(table)
                self._response:setStatus(200)
                self._response:setBody(cjson.encode(table))
                self._response:addHeader("Content-Type", "application/json")
                return self._response
            end,

            html = function(html)
                self._response:setStatus(200)
                self._response:setBody(html)
                self._response:addHeader("Content-Type", "text/html")
                return self._response
            end,

            -- Set the status code of the response
            -- @param status number The status code of the response
            status = function(status)
                self._response:setStatus(status)
                return self._response
            end,

            notFound = function()
                self._response:setStatus(404)
                self._response:setBody("Not Found")
                self._response:addHeader("Content-Type", "text/plain")
                return self._response
            end,

            -- Store key-value pairs in the context for use in request handlers
            -- @param key string The key to set
            -- @param value string The value to set
            kvSpace = {},
            set = function(key, value)
                self.kvSpace[key] = value
            end,
            -- Get a key-value pair from the context
            get = function(key)
                return self.kvSpace[key]
            end

        }
    end,

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
            self.__client = client
            self._request:_build(client)
            self._response:_bind(client)

            -- Create a context object for the route handler
            local context = self:_createContext()

            -- Find route => User callback() --
            local route = self._routes.find(self)

            if route then
                local viable = route(context)

                -- Run the route handler
                if viable then
                    context.res:send()
                end
            else
                context:notFound()
                context.res:send()
            end

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
