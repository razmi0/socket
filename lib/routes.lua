local inspect = require("lib/utils")

---@class Routes
---@field new fun(self: Routes): Routes Create a new Routes instance
---@field _has_parameter fun(self: Routes, path: string): boolean Check if the path has parameters
---@field _add_route fun(self: Routes, method: string, path: string, handler: function): nil Add a route to the router
---@field _split_path fun(self: Routes, path: string): table Split the path into parts
---@field _build_url_trie fun(self: Routes, path: string): table Build the url trie
---@field find_linear fun(self: Routes, request: Request): function|nil Find a route handler with O(1) complexity by using a linear router
---@field find_tries fun(self: Routes, request: Request): function|nil Find a route handler with O(n) complexity by using a TrieRouter
---@field find fun(self: Routes, request: Request): function|nil Find a route handler


local Routes = {}
Routes.__index = Routes

-- Create a new Routes instance
---@return Routes The new Routes instance
function Routes.new()
    local instance = setmetatable({}, Routes)
    return instance
end

-- Check if the path has parameters
---@param path string The path to check
---@return boolean True if the path has parameters, false otherwise
function Routes:_has_parameter(path)
    return path:find(":") ~= nil
end

function Routes:_split_path(path)
    local parts = {}
    for part in path:gmatch("[^/]+") do
        table.insert(parts, part)
    end
    return parts
end

-- Extract parameters from a path
---@param path string The path to extract parameters from
---@return table The parameters extracted from the path
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
function Routes:_build_url_trie(path)
    local trie = {}
    local parts = self:_split_path(path)

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
---@param handler function The handler to add to the route
function Routes:_add_route(method, path, handler)
    if not self[method] then
        self[method] = {
            indexed = {},
            tries = {}
        }
    end

    if not self:_has_parameter(path) then
        self[method].indexed[path] = handler
    else
        local trie = self:_build_url_trie(path)
        table.insert(trie, {
            handler = handler
        })
        table.insert(self[method].tries, trie)
    end
end

-- Find a route handler with O(1) complexity by using a linear router
-- The routes indexed does not have parameters
---@param request Request The request object
---@return function|nil The route handler function if found, nil otherwise
function Routes:find_linear(request)
    -- the diference comparison in lua : "nil" ~= nil
    local indexed = self[request.method].indexed[request.path]
    if indexed then
        return indexed
    end
end

-- Find a route handler with O(n) complexity by using a TrieRouter
-- The routes indexed have parameters
---@param request Request The request object
---@return function|nil The route handler function if found, nil otherwise
function Routes:find_tries(request)
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
                return trie[1].handler
            else
                current = current.next
            end
        end
    end
end

function Routes:find(request)
    local indexed = self:find_linear(request)
    if indexed then
        return indexed
    end

    local in_trie = self:find_tries(request)
    if in_trie then
        return in_trie
    end

    return nil
end

return Routes
