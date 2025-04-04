-- Check if the path has parameters
---@param path string The path to check
---@return boolean True if the path has parameters, false otherwise
local has_param = function(path)
    return path:find(":") ~= nil
end

local split_path = function(path)
    local parts = {}
    for part in path:gmatch("[^/]+") do
        table.insert(parts, part)
    end
    return parts
end

---@class Router
---@field _routes table<string> The routes
---@field new fun(self: Router): Router Create a new Router instance
---@field _register fun(self: Router, method: string, path: string, handlers: table<function>): nil Add a route to the router
---@field _build_url_trie fun(self: Router, path: string): table Build the url trie
---@field find_linear fun(self: Router, request: Request): table<function>|nil Find an array of route handlers with O(1) complexity by using a linear router
---@field find_tries fun(self: Router, request: Request): table<function>|nil Find an array of route handlers with O(n) complexity by using a TrieRouter
---@field find fun(self: Router, request: Request): table<function>|nil Find an array of route handlers


local Router = {}
Router.__index = Router

-- Create a new Router instance
---@return Router The new Router instance
function Router.new()
    local instance = setmetatable({}, Router)
    instance._routes = {}
    return instance
end

---@class Trie

-- Extract parameters from a path
---@param path string The path to extract parameters from
---@return table The parameters extracted from the path
local make_trie = function(path)
    local trie = {}
    local parts = split_path(path)

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
end

-- Add a route to the router
---@param method string The HTTP method to add the route to
---@param path string The path to add the route to
---@param handlers table<function> The handlers to add to the route
function Router:_register(method, path, handlers)
    table.insert(self._routes, method .. "@" .. path)

    if not self[method] then
        self[method] = {
            indexed = {},
            tries = {}
        }
    end

    if not has_param(path) then
        self[method].indexed[path] = handlers
    else
        local trie = make_trie(path)
        table.insert(trie, {
            handlers = handlers
        })
        table.insert(self[method].tries, trie)
    end
end

-- Find a route handler with O(1) complexity by using a linear router
-- The routes indexed does not have parameters
---@param request Request The request object
---@return table<function>|nil The route handler function if found, nil otherwise
function Router:find_linear(request)
    -- the diference comparison in lua : "nil" ~= nil
    return self[request.method].indexed[request.path]
end

-- Find a route handler with O(n) complexity by using a TrieRouter
-- The routes indexed have parameters
---@param request Request The request object
---@return table<function>|nil The route handler function if found, nil otherwise
function Router:find_tries(request)
    local parts = {}

    for part in request.path:gmatch("[^/]+") do
        table.insert(parts, part)
    end

    for _, trie in ipairs(self[request.method].tries) do
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
                return trie[1].handlers
            else
                current = current.next
            end
        end
    end
end

---@param request Request The request object
---@return table<function>|nil The route handler function if found, nil otherwise
function Router:find(request)
    -- GET@/users/:name/:id"

    local handlers = nil
    handlers = self:find_linear(request)
    if handlers then
        return handlers
    end

    handlers = self:find_tries(request)
    if handlers then
        return handlers
    end

    return nil
end

---@alias ChainHandler fun(context: Context): Response
---@alias MiddlewareHandler fun(context: Context, next: fun()): nil
---@alias Chain table<MiddlewareHandler> | ChainHandler

---@param chain Chain The handlers and middleware to run
---@param context Context The context object
---@return Response|nil
function Router:_run_chain(chain, context)
    -- last index is the handler
    -- others are middleware
    local handler = chain[#chain]
    local response = context.res

    local function dispatch(i)
        -- all middleware and handler are executed, we leave the execution flow
        if i > #chain then return end
        -- Execute final handler and store the response
        if i == #chain then
            response = handler(context)
        else
            -- Middleware execution with next control
            local nextCalled = false
            local function next()
                if not nextCalled then
                    nextCalled = true
                    dispatch(i + 1)
                end
            end

            -- Execute middleware and ignore its return value
            chain[i](context, next)
        end
    end

    dispatch(1)
    return response
end

return Router
