local socket = require("socket")
local inspect = require("lib/utils")
local request = require("lib/request")
local response = require("lib/response")
local context = require("lib/context")

---@class App
---@field _host string The host address to bind the server to
---@field _port number The port number to bind the server to
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
    -- Protected properties
    _host = arg[1] or "127.0.0.1",
    _port = tonumber(arg[2]) or 8080,

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

        findLinear = function(self, request)
            -- the diference comparison in lua : "nil" ~= nil
            local indexed = self._routes[request.method].indexed[request.path]
            if indexed then
                return indexed
            end
        end,

        findTries = function(self, request)
            -- try to find a route in the TrieRouter
            local parts = {}

            for part in request.path:gmatch("[^/]+") do
                table.insert(parts, part)
            end

            for _, trie in ipairs(self._routes[request.method].tries) do
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
                            request._params[k:gsub(":", "")] = v
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
        find = function(self, request)
            local indexed = self._routes.findLinear(self, request)
            if indexed then
                return indexed
            end

            local in_trie = self._routes.findTries(self, request)
            if in_trie then
                return in_trie
            end

            return nil
        end

    },

    -- TODO: end parsing feat
    ---Start the HTTP server and begin listening for connections
    ---@param base table Configuration table containing base.host and base.port
    ---@example
    ---@code
    ---App:start({
    ---    host = "127.0.0.1",
    ---    port = 8080
    ---})
    ---@endcode
    start = function(self, base)
        if base then
            self._host = base.host or self._host
            self._port = base.port or self._port
        end

        local server = assert(socket.bind(self._host, self._port), "Failed to bind server!")
        local ip, port = server:getsockname()
        print("Listening on http://" .. ip .. ":" .. port)

        while true do
            local client, err = server:accept()
            if not client then
                break
            end
            if err then
                print("error", err)
                break
            end
            client:settimeout(0.5)
            -- local request = require("lib/request")
            -- local response = require("lib/response")
            if request:_build(client) then
                -- Set up response
                response:_bind(client)
                -- Create a context object for the route handler
                local ctx = context:create(request, response)
                -- Find the route handler
                local route_handler = self._routes.find(self, request)
                if route_handler then
                    -- Run the route handler
                    -- Truthy value returning from the route handler is considered
                    -- as a valid condition to send the response
                    local viable = route_handler(ctx)
                    if viable then
                        ctx.res:send()
                    end
                else
                    -- Handle not found
                    ctx:notFound()
                end
            else
                print("Failed to build request")
            end

            client:close()

            -- Print some debug info
            print("<--", request.method, request.path)
            print("-->", response.status, response:header("Content-Type"))
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
