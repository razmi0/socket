local mime = require 'mimetypes'
local File = require('lib/file')

---@alias Path string
---@class ServeStaticConfig
---@field path? Path
---@field root? string


-- ```lua
-- local static = require("lib/middleware/static")
-- app:get("*", static({ root = "public" }))
-- ```

-- ```lua
-- local static = require("lib/middleware/static")
-- app:on("GET", { "/", "/:file{^.+%.%w+}" }, static(function(c)
--     return {
--         root = "public",
--         path = c.req:param("file") or "index.html"
--     }
-- end)
-- )
-- ```

---@param config ServeStaticConfig | fun(context: Context, next : fun()): ServeStaticConfig
---@return fun(context: Context, next: fun()): Response
local function static(config)
    return function(c, next)
        local conf = (type(config) == "function") and config(c, next) or config
        local root = conf.root or "./"
        local req_path = conf.path or c.req.path

        if root:sub(-1) ~= "/" then
            root = root .. "/"
        end

        local final_path
        if not req_path or req_path == "/" then
            final_path = "index.html"
        else
            final_path = req_path:sub(1, 1) == "/" and req_path:sub(2) or req_path
        end

        local fileFinder = File.new(root)
        local content = fileFinder:find(final_path)

        if not content then
            return c:notFound()
        end

        c.res:setContentType(mime.guess(final_path))
        c.res:setStatus(200)
        c.res:setBody(content)
        return c.res
    end
end

return static
