local mime = require 'mimetypes'
local File = require('lib.file')



-- static should be cache during registration phase
-- maybe that's why it is a middleware


---@class ServeStaticConfig
---@field path string The path to the file to serve
---@field root string The root directory to serve the file from

---@param config ServeStaticConfig The configuration for the serve function
---@return function The response object
local static = function(config)
    return function(c, next)
        local fileFinder = File.new(config.root)
        local content = fileFinder:find(config.path)
        if not content then
            return c:notFound()
        end
        local mimeType = mime.guess(config.path)
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
