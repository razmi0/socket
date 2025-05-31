local cjson = require "cjson"
local mime = require 'mimetypes'
local File = require('lib/file')

---@class Context
---@field req Request The request object
---@field res Response The response object
---@field kvSpace table The key-value store for request handlers
---@field header fun(key: string, value: string): Response Add a header to the response
---@field body fun(body: string, status: number?, headers: table?): Response Set the body of the response
---@field text fun(text: string): Response Set the body of the response to a text string
---@field json fun(table: table): Response Set the body of the response to a JSON string
---@field html fun(html: string): Response Set the body of the response to an HTML string
---@field status fun(status: number): Response Set the status code of the response
---@field notFound fun(): Response Set the status code to 404 and the body to "404 Not Found"
---@field internalErr fun(): Response Set the status code to 500 and the body to "500 Internal Server Error"
---@field set fun(key: string, value: string): nil Set a key-value pair in the context
---@field get fun(key: string): string Get a key-value pair from the context
---@field new fun(request: Request, response: Response): Context Create a new context
---@field header fun(key: string, value: string): Response Add a header to the response
---@field body fun(body: string, status: number?, headers: table?): Response Set the body of the response
---@field text fun(text: string): Response Set the body of the response to a text string
---@field json fun(table: table): Response Set the body of the response to a JSON string
---@field html fun(html: string): Response Set the body of the response to an HTML string
---@field status fun(status: number): Response Set the status code of the response
---@field serve fun(config: ServeStaticConfig): Response Serve a static file
---@field redirect fun(url: string): Response Redirect to a URL
---@field  _finalized boolean
---@field  _err_handler fun():Response|nil


local Context = {}
Context.__index = Context

---@param request Request The request object
---@param response Response The response object
---@return Context
function Context.new(request, response)
    local instance = setmetatable({}, Context)
    instance.req = request
    instance.res = response
    instance.kvSpace = {}
    instance._finalized = false
    instance._err_handler = nil
    return instance
end

---@param key string The key to add to the response header
---@param value string The value to add to the response header
---@return Response The response object
function Context:header(key, value)
    self.res:addHeader(key, value)
    return self.res
end

---@param body string The body to set in the response
---@param status number? The status code to set in the response
---@param headers table? The headers to add to the response
---@return Response The response object
function Context:body(body, status, headers)
    self.res:setBody(body)
    if status then
        self.res:setStatus(status)
    end
    if headers then
        for key, value in pairs(headers) do
            self.res:addHeader(key, value)
        end
    end
    return self.res
end

---@param text string The text to set in the response
---@return Response The response object
function Context:text(text)
    self.res:setStatus(200)
    self.res:setBody(text)
    self.res:addHeader("Content-Type", "text/plain")
    return self.res
end

---@param table table The table to set in the response
---@return Response The response object
function Context:json(table)
    self.res:setStatus(200)
    self.res:setBody(cjson.encode(table))
    self.res:addHeader("Content-Type", "application/json")
    return self.res
end

---@param html string The HTML to set in the response
---@return Response The response object
function Context:html(html)
    self.res:setStatus(200)
    self.res:setBody(html)
    self.res:addHeader("Content-Type", "text/html")
    return self.res
end

---@param status number The status code to set in the response
---@return Response The response object
function Context:status(status)
    self.res:setStatus(status)
    return self.res
end

---@return Response The response object
function Context:notFound()
    -- setContentType fun(self: Response, contentType: string): Response Set the Content-Type header
    self.res:setContentType("text/plain")
    self.res:setStatus(404)
    self.res:setBody("404 Not Found")
    return self.res
end

---@return Response The response object
function Context:internalErr()
    -- setContentType fun(self: Response, contentType: string): Response Set the Content-Type header
    self.res:setContentType("text/plain")
    self.res:setStatus(500)
    self.res:setBody("500 Internal Server Error")
    return self.res
end

---@param key string The key to set in the context
---@param value string The value to set in the context
function Context:set(key, value)
    self.kvSpace[key] = value
end

---@param key string The key to get from the context
---@return string The value of the key
function Context:get(key)
    return self.kvSpace[key]
end

--------------------------------
-- Serve Static Files
--------------------------------

---@param config ServeStaticConfig The configuration for the serve function
---@return Response The response object
function Context:serve(config)
    local fileFinder = File.new(config.root)
    local content = fileFinder:find(config.path)
    if not content then
        return self:notFound()
    end
    local mimeType = mime.guess(config.path)
    self.res:setContentType(mimeType)
    self.res:setStatus(200)
    self.res:setBody(content)
    return self.res
end

---@param url string The URL to redirect to
---@return Response The response object
function Context:redirect(url)
    self.res:setStatus(302)
    self.res:addHeader("Location", url)
    return self.res
end

return Context
