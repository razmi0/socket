---@class RouteNode
---@field static table
---@field param table
---@field wildcard table|nil
---@field handlers Chain|nil
---@field isOptionnal boolean
---@field userPattern string|nil
---@field __order table

---@alias Methods "GET"|"POST"|"PUT"|"DELETE"
---@alias Handler fun(context: Context): nil|Response
---@alias Middleware fun(context: Context, next: fun()): nil
---@alias MiddlewaresHandler fun(context: Context, next?: fun()): nil|Response
---@alias Chain MiddlewaresHandler[]

---@class Router
---@field new fun(): Router Create a new Router instance
---@field routes table
---@field _add_route fun(self: Router, methods : Methods, path : string, handlers : Chain)
---@field _match fun(self: Router, methods : Methods, path : string):Chain?, boolean, table<string,string>
---@field _run_route fun(self: Router, chain : Chain, context : Context):Response|nil

local Router = {}
Router.__index = Router

-- Create a new Router instance
---@return Router
function Router.new()
    local instance = setmetatable({}, Router)
    instance.routes = {}
    return instance
end

---@return RouteNode
local function createNode()
    return {
        static = {},        -- Exact-match segments.
        param = {},         -- Dynamic segments.
        wildcard = nil,     -- Wildcard catch-all.
        handlers = nil,     -- Handlers at this node.
        isOptional = false, -- For dynamic nodes, true if the parameter is optional.
        userPattern = nil,  -- Lua pattern (string) for validation, if provided.
        __order = {}
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
    if str == "*" and str ~= "wildcard" then
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



---@param method Methods | "ALL" | "USE"
---@param path string
---@param handlers Chain
function Router:_add_route(method, path, handlers)
    method = method:upper()
    path = path or "*"
    local segments = splitPath(path)
    local function register(met)
        local function insertOrdered(node, kind, key)
            -- Prevent duplicates in __order
            for _, entry in ipairs(node.__order) do
                if entry.kind == kind and entry.key == key then
                    return
                end
            end
            table.insert(node.__order, { kind = kind, key = key })
        end
        if not self.routes[met] then
            self.routes[met] = createNode()
        end

        local node = self.routes[met]

        -- all methods

        for _, seg in ipairs(segments) do
            local segType, paramName, userPattern, isOptional = parseSegment(seg)

            if segType == "static" then
                node.static[paramName] = node.static[paramName] or createNode()
                insertOrdered(node, "static", paramName)
                node = node.static[paramName]
            elseif segType == "param" then
                node.param[paramName] = node.param[paramName] or createNode()
                insertOrdered(node, "param", paramName)
                node = node.param[paramName]
                node.isOptional = isOptional
                if userPattern then
                    node.userPattern = userPattern
                end
            elseif segType == "wildcard" then
                node.wildcard = node.wildcard or createNode()
                insertOrdered(node, "wildcard", "*")
                node = node.wildcard
            end
        end


        node.handlers = node.handlers or {}
        for _, handler in ipairs(handlers) do
            table.insert(node.handlers, handler)
        end
    end

    if method == "ALL" or method == "USE" then
        local mets = { "GET", "POST", "PUT", "DELETE" }
        for _, m in ipairs(mets) do
            register(m)
        end

        return
    else
        register(method)
    end
end

-- OTHERS

---@param node RouteNode
---@param segments string[]
---@param index number
---@param temp_params table<string,string>
---@return RouteNode|nil , table<string,string>|nil
local function traverse(node, segments, index, temp_params)
    if index > #segments then
        if node.handlers then
            return node, temp_params
        end
        -- Try to match optional parameters
        for _, entry in ipairs(node.__order) do
            if entry.kind == "param" then
                local child = node.param[entry.key]
                if child and child.isOptional then
                    local res, paramsFound = traverse(child, segments, index, temp_params)
                    if res then return res, paramsFound end
                end
            end
        end
        return nil, nil
    end

    local seg = segments[index]

    for _, entry in ipairs(node.__order) do
        local child

        if entry.kind == "static" and seg == entry.key then
            child = node.static[entry.key]
            local res, paramsFound = traverse(child, segments, index + 1, temp_params)
            if res then return res, paramsFound end
        elseif entry.kind == "param" then
            child = node.param[entry.key]
            if child then
                if child.userPattern then
                    if seg:match(child.userPattern) then
                        temp_params[entry.key] = seg
                        local res, paramsFound = traverse(child, segments, index + 1, temp_params)
                        if res then return res, paramsFound end
                        temp_params[entry.key] = nil
                    end
                else
                    temp_params[entry.key] = seg
                    local res, paramsFound = traverse(child, segments, index + 1, temp_params)
                    if res then return res, paramsFound end
                    temp_params[entry.key] = nil
                end

                if child.isOptional then
                    local res, paramsFound = traverse(child, segments, index, temp_params)
                    if res then return res, paramsFound end
                end
            end
        elseif entry.kind == "wildcard" and node.wildcard then
            child = node.wildcard
            if not child then
                return nil, nil
            end
            local res, paramsFound = traverse(child, segments, index + 1, temp_params)
            if res then return res, paramsFound end
        end
    end

    return nil, nil
end

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
    -- an alternative, possibly O1, would be to store all paths in a set (e.g Array<string,true>)
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
    local params = matched_params or {}
    return handlers, found_path, params
end

function Router:_run_route(chain, context)
    -- last index is the handler
    -- others are middleware
    local handler = chain[#chain]
    ---@type Response|nil
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
