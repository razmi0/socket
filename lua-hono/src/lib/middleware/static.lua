local mime = require 'mimetypes'
local File = require('lib.file')



-- static should be cache during registration phase
-- maybe that's why it is a middleware
---@alias Path string

---@class ServeStaticConfig
---@field path? string The path to the file to serve
---@field root? string The root directory to serve the file from

---@param config ServeStaticConfig|fun(context : Context, next : fun()): Path The configuration for the serve function
---@return function The response object
local static = function(config)
    local root = type(config) == "table" and config.root or "./"
    local path = type(config) == "table" and config.path or "index.html"
    local fn = function(c, next)
        if type(config) == "function" then
            path = config(c, next)
        end

        local fileFinder = File.new(root)
        local content = fileFinder:find(path)
        if not content then
            return c:notFound()
        end
        local mimeType = mime.guess(path)
        c.res:setContentType(mimeType)
        c.res:setStatus(200)
        c.res:setBody(content)
        return c.res
    end
    return fn
end

return static


--------------------------------
-- Serve Static Files
--------------------------------
