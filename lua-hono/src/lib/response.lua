---@class Response
---@field new fun(client: table): Response Create a new Response instance
---@field msgFromCode fun(self : Response, code : number) : string Return the status message from a status code
---@field _current string The current built response string
---@field _client table The socket client instance
---@field protocol string The protocol of the response
---@field status number The HTTP status code
---@field statusMessage string The HTTP status message
---@field body string The response body
---@field _headers table<string, string> The headers of the response
---@field header fun(self: Response, key: string|nil): table|string|nil Get a header value or all headers
---@field setStatus fun(self: Response, status: number): Response Set the HTTP status code and message
---@field setBody fun(self: Response, body: string): Response Set the response body and update related headers
---@field addHeader fun(self: Response, key: string, value: string): Response Add or update a response header
---@field setContentType fun(self: Response, contentType: string): Response Set the Content-Type header
---@field send fun(self: Response): nil Send the response to the client
---@field _build fun(self: Response): nil Build the complete HTTP response string


local Response = {}
Response.__index = Response
Response.__name = "Response"

-- Static status code messages
local STATUS_CODES = {
    [200] = "OK",
    [201] = "Created",
    [202] = "Accepted",
    [204] = "No Content",
    [303] = "See Other",
    [400] = "Bad Request",
    [401] = "Unauthorized",
    [403] = "Forbidden",
    [404] = "Not Found",
    [405] = "Method Not Allowed",
    [500] = "Internal Server Error"
}

-- Default properties for a new Response object
-- especially usefull for the constructor
local default_response = {
    _current = "",
    _client = nil,
    protocol = "HTTP/1.1",
    status = 200,
    statusMessage = "OK",
    body = "",
    _headers = {
        ["Content-Type"] = "application/json",
        ["Content-Length"] = "0",
        ["X-Powered-By"] = "Raz",
        ["Date"] = os.date("%a, %d %b %Y %H:%M:%S GMT"),
        ["Last-Modified"] = os.date("%a, %d %b %Y %H:%M:%S GMT"),
    }
}

---Constructor for the Response object
---@param client table The socket client instance
---@return Response
function Response.new(client)
    local instance = setmetatable({}, Response)
    for key, value in pairs(default_response) do
        instance[key] = value
    end
    instance._headers = {}
    for key, value in pairs(default_response._headers) do
        instance._headers[key] = value
    end
    if client then
        instance._client = client
    else
        error("Client failed to bind to response")
    end
    instance:_build()
    return instance
end

--- Get a header value or all headers
--- @param key string|nil The header key to retrieve, or nil to get all headers
--- @return table|string|nil The header value, all headers, or nil if not found
function Response:header(key)
    if not key then
        return self._headers
    end
    return self._headers[key]
end

---- - Set the HTTP status code and message
---- - @param status number The HTTP status code (e.g., 200, 404, 500)
---- - @return Response self The response instance for method chaining
function Response:setStatus(status)
    self.status = status
    self.statusMessage = STATUS_CODES[status] or "Unknown"
    return self
end

---@param code number Status code
---@return string message
function Response:msgFromCode(code)
    return STATUS_CODES[code] or "Unknown"
end

--- Set the response body and update related headers
--- @param body string The response body content
--- @return Response self The response instance for method chaining
function Response:setBody(body)
    self.body = body
    self._headers["Content-Length"] = #body
    self._headers["Last-Modified"] = os.date("%a, %d %b %Y %H:%M:%S GMT")
    return self
end

--- Add or update a response header
--- @param key string The header key
--- @param value string The header value
--- @return Response self The response instance for method chaining
function Response:addHeader(key, value)
    self._headers[key] = value
    return self
end

--- Set the Content-Type header
--- @param contentType string The content type (e.g., "application/json", "text/html")
--- @return Response self The response instance for method chaining
function Response:setContentType(contentType)
    self._headers["Content-Type"] = contentType
    return self
end

--- Send the response to the client
function Response:send()
    self:_build()
    self._client:send(self._current)
end

--- Build the complete HTTP response string
--- The raw http response (_current) is built when the instance is created and before sending to the client
--- In between, the response can be modified
--- @private
function Response:_build()
    local heading = ("%s %d %s\r\n"):format(
        self.protocol,
        self.status,
        self.statusMessage
    )
    local headers = ""
    for key, value in pairs(self._headers) do
        if value ~= nil then
            headers = headers .. ("%s: %s\r\n"):format(key, value)
        end
    end
    self._current = heading .. headers .. "\r\n" .. self.body
end

return Response
