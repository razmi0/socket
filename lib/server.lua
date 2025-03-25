local socket = require("socket")
local Request = require("lib/request")
local Response = require("lib/response")
local cjson = require "cjson"
local inspect = require("lib/utils")

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
---@field put fun(self: App, path: string, callback: function): nil Register a PUT route handler
---@field delete fun(self: App, path: string, callback: function): nil Register a DELETE route handler
---@field patch fun(self: App, path: string, callback: function): nil Register a PATCH route handler
---@field options fun(self: App, path: string, callback: function): nil Register a OPTIONS route handler
---@field head fun(self: App, path: string, callback: function): nil Register a HEAD route handler
local App = {
    __client = nil,
    -- Protected properties
    _host = "localhost",
    _port = 0,
    _server = nil,
    _request = Request,
    _response = Response,

    _routes = {
        GET = {
            -- for TrieRouter
            tries = {},
            -- for LinearRouter
            indexed = {}
        },
        POST = {
            tries = {},
            indexed = {}
        },
        PUT = {
            tries = {},
            indexed = {}
        },
        DELETE = {
            tries = {},
            indexed = {}
        },
        PATCH = {
            tries = {},
            indexed = {}
        },
        OPTIONS = {
            tries = {},
            indexed = {}
        },
        HEAD = {
            tries = {},
            indexed = {}
        },

        findLinear = function(self)
            -- the diference comparison in lua : "nil" ~= nil
            local indexed = self._routes[self._request.method].indexed[self._request.path]
            if indexed then
                return indexed
            end
        end,

        findTries = function(self)
            -- try to find a route in the TrieRouter
            local parts = {}

            for part in self._request.path:gmatch("[^/]+") do
                table.insert(parts, part)
            end

            for _, trie in ipairs(self._routes[self._request.method].tries) do
                local current = trie
                local temp_params = {}

                for i = 1, #parts do
                    local part = parts[i]
                    if current.is_param then
                        temp_params[current.value] = part
                    else
                        if part ~= current.value then
                            break
                        end
                    end

                    if current.done then
                        for k, v in pairs(temp_params) do
                            self._request._params[k:gsub(":", "")] = v
                        end
                        return trie[1].callback
                    else
                        current = current.next
                    end

                end

            end
        end,

        ---Find a route handler based on the current request method and path
        ---@return function|nil The route handler function if found, nil otherwise
        find = function(self)
            local indexed = self._routes.findLinear(self)
            if indexed then
                return indexed
            end

            local in_trie = self._routes.findTries(self)
            if in_trie then
                return in_trie
            end

            return nil
        end

    },

    -- TODO: end parsing feat
    -- TODO: path params

    -- Context object for request handlers
    -- has a lot of helper functions for sending responses(c:)
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

    has_parameter = function(self, path)
        return path:find(":") ~= nil
    end,

    -- Extract parameters from a path
    -- example: /users/:id
    -- will return : 
    -- {
    --     value = "users",
    --     is_param = false,
    --     done = false,
    --     next = {
    --         value = "id",
    --         is_param = true,
    --         done = true,
    --     }
    -- }
    -- @param path string The path to extract parameters from
    -- @return table The parameters extracted from the path
    _build_url_trie = function(self, path)
        local trie = {}

        function split(path)
            local parts = {}
            for part in path:gmatch("[^/]+") do
                table.insert(parts, part)
            end
            return parts
        end

        -- Split path into parts
        local parts = split(path)

        -- Create the trie structure
        local current = trie
        for i = 1, #parts do
            local part = parts[i]
            local is_param = part:match("^:") ~= nil

            -- Create node
            current.is_param = is_param
            current.value = part

            -- Add next pointer if not last element
            if i < #parts then
                current.next = {}
                current = current.next
                current.done = false
            else
                current.done = true
            end
        end

        return trie
    end,

    ---Register a GET route handler
    ---@param path string The URL path to handle
    ---@param callback function The callback function to handle the route
    get = function(self, path, callback)
        if not self:has_parameter(path) then
            -- more like a classic path indexing route
            -- complexity: O(1)
            self._routes.GET.indexed[path] = callback
        else
            -- more like a TrieRouter (with params)
            -- complexity: O(n)
            local trie = self:_build_url_trie(path)
            table.insert(trie, {
                callback = callback
            })
            table.insert(self._routes.GET.tries, trie)
        end

    end,

    ---Register a POST route handler
    ---@param path string The URL path to handle
    ---@param callback function The callback function to handle the route
    post = function(self, path, callback)
        self._routes.POST[path] = callback
    end,

    ---Register a PUT route handler
    ---@param path string The URL path to handle
    ---@param callback function The callback function to handle the route
    put = function(self, path, callback)
        self._routes.PUT[path] = callback
    end,

    ---Register a DELETE route handler
    ---@param path string The URL path to handle
    ---@param callback function The callback function to handle the route
    delete = function(self, path, callback)
        self._routes.DELETE[path] = callback
    end,

    ---Register a PATCH route handler
    ---@param path string The URL path to handle
    ---@param callback function The callback function to handle the route
    patch = function(self, path, callback)
        self._routes.PATCH[path] = callback
    end,

    ---Register a OPTIONS route handler
    ---@param path string The URL path to handle
    ---@param callback function The callback function to handle the route
    options = function(self, path, callback)
        self._routes.OPTIONS[path] = callback
    end,

    ---Register a HEAD route handler
    ---@param path string The URL path to handle
    ---@param callback function The callback function to handle the route
    head = function(self, path, callback)
        self._routes.HEAD[path] = callback
    end
}
return App
