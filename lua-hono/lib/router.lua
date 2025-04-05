-- -- Check if the path has parameters
-- ---@param path string The path to check
-- ---@return boolean True if the path has parameters, false otherwise
-- local has_param = function(path)
--     return path:find(":") ~= nil
-- end

-- local split_path = function(path)
--     local parts = {}
--     for part in path:gmatch("[^/]+") do
--         table.insert(parts, part)
--     end
--     return parts
-- end


---@alias Methods "GET"|"POST"|"PUT"|"DELETE"
---@alias Handler fun(context: Context): nil|Response
---@alias Middleware fun(context: Context, next: fun()): nil
---@alias MiddlewaresHandler fun(context: Context, next?: fun()): nil|Response
---@alias Chain MiddlewaresHandler[]

---@class Router
---@field new fun(self: Router): Router Create a new Router instance
---@field routes table
---@field _register fun(self: Router, methods : Methods, path : string, handlers : Chain)
---@field _match fun(self: Router, methods : Methods, path : string)
---@field _run_route fun(self: Router, chain : Chain, context : Context)
local Router = {}
Router.__index = Router

-- Create a new Router instance
---@return Router
function Router.new()
    local instance = setmetatable({}, Router)
    instance.routes = {}
    return instance
end

---@class RouteNode
---@field static table
---@field param table
---@field wildcard table|nil
---@field handlers Chain|nil
---@field isOptionnal boolean
---@field userPattern string|nil

---@return RouteNode
local function createNode()
    return {
        static = {},        -- Exact-match segments.
        param = {},         -- Dynamic segments.
        wildcard = nil,     -- Wildcard catch-all.
        handlers = nil,     -- Handlers at this node.
        isOptional = false, -- For dynamic nodes, true if the parameter is optional.
        userPattern = nil   -- Lua pattern (string) for validation, if provided.
    }
end

---@param path string
---@return string[]
local function splitPath(path)
    local segments = {}
    for segment in string.gmatch(path, "[^/]+") do
        table.insert(segments, segment)
    end
    return segments
end

---@param str string
---@return "param"|"static"|"wildcard", string, string|nil, boolean
local function parseSegment(str)
    -- Wildcard segment.
    if str == "*" then
        return "wildcard", str, nil, false
    end

    local paramName, optionalFlag, patternPart = str:match("^:([%w%-%_]+)(%??){?(.-)}?$")
    if paramName then
        local isOptional = (optionalFlag == "?")
        if patternPart == "" then
            patternPart = nil
        end
        return "param", paramName, patternPart, isOptional
    end

    -- Otherwise, it's a static segment.
    return "static", str, nil, false
end

---@param node RouteNode
---@param segments string[]
---@param index number
---@param temp_params table<string,string>
local function traverse(node, segments, index, temp_params)
    -- Base case: all segments have been processed.
    if index > #segments then
        if node.handlers then
            return node, temp_params
        end
        -- If there is an optional dynamic parameter available, try to skip it.
        for _, child in pairs(node.param) do
            if child.isOptional then
                local res, paramsFound = traverse(child, segments, index, temp_params)
                if res then return res, paramsFound end
            end
        end
        return nil, nil
    end

    local seg = segments[index]

    -- 1. Try static children first.
    if node.static[seg] then
        local res, paramsFound = traverse(node.static[seg], segments, index + 1, temp_params)
        if res then return res, paramsFound end
    end

    -- 2. Try dynamic (param) children.
    for paramName, child in pairs(node.param) do
        -- If a userPattern is provided, validate the current segment.
        if child.userPattern then
            if seg:match(child.userPattern) then
                temp_params[paramName] = seg
                local res, paramsFound = traverse(child, segments, index + 1, temp_params)
                if res then return res, paramsFound end
                temp_params[paramName] = nil
            end
        else
            temp_params[paramName] = seg
            local res, paramsFound = traverse(child, segments, index + 1, temp_params)
            if res then return res, paramsFound end
            temp_params[paramName] = nil
        end

        -- If the dynamic segment is optional, try skipping it.
        if child.isOptional then
            local res, paramsFound = traverse(child, segments, index, temp_params)
            if res then return res, paramsFound end
        end
    end

    -- 3. Try wildcard if present.
    if node.wildcard then
        local res, paramsFound = traverse(node.wildcard, segments, index + 1, temp_params)
        if res then return res, paramsFound end
    end

    return nil, nil
end

---@param method Methods
---@param path string
---@param handlers Chain
function Router:_register(method, path, handlers)
    local segments = splitPath(path)
    method = method:upper()

    if not self.routes[method] then
        self.routes[method] = createNode()
    end

    local node = self.routes[method]

    for _, seg in ipairs(segments) do
        local segType, paramName, userPattern, isOptional = parseSegment(seg)

        if segType == "static" then
            node.static[paramName] = node.static[paramName] or createNode()
            node = node.static[paramName]
        elseif segType == "param" then
            node.param[paramName] = node.param[paramName] or createNode()
            node = node.param[paramName]
            -- Attach additional properties to the dynamic node.
            node.isOptional = isOptional
            if userPattern then
                node.userPattern = userPattern
            end
        elseif segType == "wildcard" then
            node.wildcard = node.wildcard or createNode()
            node = node.wildcard
        end
    end

    node.handlers = node.handlers or {}
    for _, handler in ipairs(handlers) do
        table.insert(node.handlers, handler)
    end
end

--- Return handlers, found_path flag, params stored
---@param method Methods
---@param path string
---@return Chain, boolean, table<string,string>
function Router:_match(method, path)
    local segments = splitPath(path)
    local temp_params = {}
    local matched_node, matched_params = nil, nil
    local found_path = false


    -- Attempt to match the route under the requested method.
    if self.routes[method] then
        matched_node, matched_params = traverse(self.routes[method], segments, 1, temp_params)
        if matched_node then
            found_path = true
        end
    end

    -- If no match under the requested method, try all other methods
    -- to determine if the path exists for a different HTTP method.
    if not matched_node then
        for m, node in pairs(self.routes) do
            if m ~= method then
                local res, _ = traverse(node, segments, 1, {}) -- Use a fresh table for each try.
                if res then
                    found_path = true
                    break
                end
            end
        end
    end

    local handlers = matched_node and matched_node.handlers or nil
    local found_path = found_path
    local params = matched_params or {}

    return handlers, found_path, params
end

---@param chain Chain The handlers and middleware to run
---@param context Context The context object
---@return Response|nil
function Router:_run_route(chain, context)
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


-- ---@class Trie

-- -- Extract parameters from a path
-- ---@param path string The path to extract parameters from
-- ---@return table The parameters extracted from the path
-- local make_trie = function(path)
--     local trie = {}
--     local parts = split_path(path)

--     -- Create the trie structure
--     local current = trie
--     for i = 1, #parts do
--         local part = parts[i]
--         local is_param = part:match("^:") ~= nil

--         -- Create node
--         current.is_param = is_param
--         current.value = part

--         -- Add next pointer if not last element
--         if i < #parts then
--             current.next = {}
--             current = current.next
--             current.done = false
--         else
--             current.done = true
--         end
--     end

--     return trie
-- end

-- -- Add a route to the router
-- ---@param method string The HTTP method to add the route to
-- ---@param path string The path to add the route to
-- ---@param handlers table<function> The handlers to add to the route
-- function Router:_register(method, path, handlers)
--     table.insert(self._routes, method .. "@" .. path)

--     if not self[method] then
--         self[method] = {
--             indexed = {},
--             tries = {}
--         }
--     end

--     if not has_param(path) then
--         self[method].indexed[path] = handlers
--     else
--         local trie = make_trie(path)
--         table.insert(trie, {
--             handlers = handlers
--         })
--         table.insert(self[method].tries, trie)
--     end
-- end

-- -- Find a route handler with O(1) complexity by using a linear router
-- -- The routes indexed does not have parameters
-- ---@param request Request The request object
-- ---@return table<function>|nil The route handler function if found, nil otherwise
-- function Router:find_linear(request)
--     -- the diference comparison in lua : "nil" ~= nil
--     return self[request.method].indexed[request.path]
-- end

-- -- Find a route handler with O(n) complexity by using a TrieRouter
-- -- The routes indexed have parameters
-- ---@param request Request The request object
-- ---@return table<function>|nil The route handler function if found, nil otherwise
-- function Router:find_tries(request)
--     local parts = {}

--     for part in request.path:gmatch("[^/]+") do
--         table.insert(parts, part)
--     end

--     for _, trie in ipairs(self[request.method].tries) do
--         local current = trie
--         local temp_params = {}

--         for i = 1, #parts do
--             local part = parts[i]
--             if current.is_param then
--                 temp_params[current.value] = part
--             else
--                 if part ~= current.value then
--                     break
--                 end
--             end

--             if current.done then
--                 for k, v in pairs(temp_params) do
--                     request._params[k:gsub(":", "")] = v
--                 end
--                 return trie[1].handlers
--             else
--                 current = current.next
--             end
--         end
--     end
-- end

-- ---@param request Request The request object
-- ---@return table<function>|nil The route handler function if found, nil otherwise
-- function Router:find(request)
--     -- GET@/users/:name/:id"

--     local handlers = nil
--     handlers = self:find_linear(request)
--     if handlers then
--         return handlers
--     end

--     handlers = self:find_tries(request)
--     if handlers then
--         return handlers
--     end

--     return nil
-- end
