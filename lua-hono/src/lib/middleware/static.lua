local mime = require 'mimetypes'
local File = require('lib.file')



-- static should be cache during registration phase
-- maybe that's why it is a middleware
---@alias Path string

---@class ServeStaticConfig
---@field path? Path The path to the file to serve
---@field root? string The root directory to serve the file from

---@param config ServeStaticConfig |fun(context : Context, next : fun()): ServeStaticConfig a function or an object to configure middleware
---@return fun(context : Context, next : fun()): Response
local static = function(config)
    return function(c, next)
        local conf = type(config) == "function" and config(c, next) or config
        local root = type(conf) == "table" and conf.root or "./"
        local path = type(conf) == "table" and conf.path or "/index.html"
        if (path:sub(1, 1) ~= "/") or (root:sub(#root) ~= "/") then
            path = "/" .. path
        end
        local fileFinder = File.new(root)
        local content = fileFinder:find(path)
        if not content then return c:notFound() end
        local mimeType = mime.guess(path)
        c.res:setContentType(mimeType)
        c.res:setStatus(200)
        c.res:setBody(content)
        return c.res
    end
end

return static


--------------------------------
-- Serve Static Files
--------------------------------
