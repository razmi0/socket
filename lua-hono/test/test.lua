local inspect = require("inspect")

-- local function createNode()
--     return {
--         static = {},    -- Enfants statiques (segments exacts)
--         param = {},     -- Enfants dynamiques (avec patterns Lua)
--         wildcard = nil, -- Correspondance générique (*)
--         handlers = nil  -- Handlers attachés à ce nœud
--     }
-- end



-- local function splitPath(path)
--     local segments = {}
--     for segment in string.gmatch(path, "[^/]+") do
--         table.insert(segments, segment)
--     end
--     return segments
-- end

-- local function parseSegment(str)
--     if str == "*" then
--         return "wildcard", str
--     elseif str:match(":%w+") then
--         local seg = str:match("(%w+)")
--         if str:match(":%w+?") then
--             return "optional", seg
--         end
--         if str:match("{.-}") then
--             local user_pattern = str:match("{(.-)}")
--             return "pattern", seg, user_pattern
--         end
--         return "param", seg
--     else
--         return "static", str
--     end
-- end

-- function Router:register(method, path, handler)
--     local segments = splitPath(path)
--     method = method:upper()

--     if not self.routes[method] then
--         self.routes[method] = createNode()
--     end

--     local node = self.routes[method]

--     for _, seg in ipairs(segments) do
--         local segType, pattern, user_pattern = parseSegment(seg)

--         if segType == "static" then
--             node.static[pattern] = node.static[pattern] or createNode()
--             node = node.static[pattern]
--         elseif segType == "param" then
--             node.param[pattern] = node.param[pattern] or createNode()
--             node.param[pattern].pattern = pattern
--             node = node.param[pattern]
--         elseif segType == "wildcard" then
--             node.wildcard = node.wildcard or createNode()
--             node = node.wildcard
--         end
--     end

--     node.handlers = node.handlers or {}
--     table.insert(node.handlers, handler)
-- end

-- function Router:match(method, path)
--     local segments = splitPath(path)
--     method = method:upper()
--     local root = self.routes[method]
--     if not root then return nil end

--     local params = {}

--     local function traverse(node, index)
--         if index > #segments then
--             return node.handlers and node, params
--         end

--         local seg = segments[index]

--         -- 1. Correspondance exacte
--         if node.static[seg] then
--             local res, p = traverse(node.static[seg], index + 1)
--             if res then return res, p end
--         end

--         -- 2. Correspondance dynamique
--         for pattern, paramNode in pairs(node.param) do
--             if seg:match(pattern) then
--                 params[pattern] = seg
--                 local res, p = traverse(paramNode, index + 1)
--                 if res then return res, p end
--                 params[pattern] = nil
--             end
--         end

--         -- 3. Correspondance par joker
--         if node.wildcard then
--             return traverse(node.wildcard, index + 1)
--         end

--         return nil
--     end

--     return traverse(root, 1)
-- end

-- === TESTS ===

local Router = {}
Router.__index = Router

function Router:new()
    local instance = {
        routes = {} -- Arbre de routes par méthode HTTP
    }
    setmetatable(instance, self)
    return instance
end

local str_1 = ":date?{%d+}"
local str_2 = "user"
local str_3 = ":name?"
local str_4 = ":name{%a+}"

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

local function splitPath(path)
    local segments = {}
    for segment in string.gmatch(path, "[^/]+") do
        table.insert(segments, segment)
    end
    return segments
end

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

function Router:register(method, path, handler)
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
    table.insert(node.handlers, handler)
end

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

-- Router:match function.
-- It takes a method and a full path.
-- Returns a table with:
--   found_method: true if a matching route exists under the given method.
--   handlers: the list of handler functions if a route is found (nil otherwise).
--   found_path: true if a route exists for the given path under any method.
--   params: table of parameter names and values extracted from the path.
function Router:match(method, path)
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

    return {
        handlers = matched_node and matched_node.handlers or nil,
        found_path = found_path,
        params = matched_params or {}
    }
end

local router = Router:new()

router:register("GET", "/users/:id?{%d+}/profile", function(params)
    return "User Profile for ID: " .. (params.id or "default")
end)

router:register("GET", "/docs/:param_1/:param_2/:param_3/:param_4", function(params)
    return "User Profile for ID: " .. (params.id or "default")
end)

router:register("GET", "/users/:name{%a+}", function(params)
    return "Utilisateur : " .. params["%a+"]
end)

router:register("GET", "/files/:id{%d+}", function(params)
    return "Fichier : " .. params["%d+"]
end)

router:register("GET", "/any/*/*", function()
    return "Wildcard Match!"
end)

router:register("GET", "/:thing?", function()
    return "Wildcard Match!"
end)
-- print(inspect(router.routes))

print("/thing" .. inspect(router:match("GET", "/thing"))) -- found ok

-- print("/any/static_1/static_2" .. inspect(router:match("GET", "/any/static_1/static_2"))) -- found ok
-- print("/users/123/profile" .. inspect(router:match("GET", "/users/123/profile")))                       -- found ok
-- print("/docs/value/value/value/value" .. inspect(router:match("GET", "/docs/value/value/value/value"))) -- found ok
-- print("/users/profile" .. inspect(router:match("GET", "/users/profile")))                               -- found ok
-- print("/users/john" .. inspect(router:match("GET", "/users/john")))                                     -- found ok
-- print("/users/123" .. inspect(router:match("GET", "/users/123")))                                       -- not found ok
-- print("/files/123" .. inspect(router:match("GET", "/files/123")))                                       -- found ok
-- print("/files/string" .. inspect(router:match("GET", "/files/string")))                                 -- not found ok

print("/users/123/profile" .. inspect(router:match("POST", "/users/123/profile"))) -- not found ok (405)
-- print("/users/coucou/profile" .. inspect(router:match("GET", "/users/coucou/profile")))                 -- not found ok


-- -- Test des routes
-- local node, params = router:match("GET", "/users/Alice")
-- if node and node.handlers then
--     print(node.handlers[1](params)) -- "Utilisateur : Alice"
-- end

-- local node2, params2 = router:match("GET", "/files/123")
-- if node2 and node2.handlers then
--     print(node2.handlers[1](params2)) -- "Fichier : 123"
-- end

-- local node3 = router:match("GET", "/any/anything/here")
-- if node3 and node3.handlers then
--     print(node3.handlers[1]()) -- "Wildcard Match!"
-- end
