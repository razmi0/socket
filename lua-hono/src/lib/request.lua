---@class Request
---@field _client table The socket client instance
---@field _headers table<string, string> The headers of the request
---@field _queries table<string, string> The queries of the request
---@field _params table<string, string> The parameters of the request
---@field method string The method of the request
---@field path string The path of the request
---@field protocol string The protocol of the request
---@field body string The body of the request
---@field hasBody boolean Whether the request has a body
---@field bodyType string The type of the body
---@field bodyParsed boolean Whether the body has been parsed
---@field new fun(client : unknown): Request Contructor
---@field _parse fun(self: Request): boolean Parse the request (heading, headers, body)
---@field header fun(self: Request, key: string): string|table Get a header value or all headers
---@field query fun(self: Request, key: string): string|table Get a query value or all queries
---@field param fun(self: Request, key: string): string|table Get a parameter value or all parameters
---@field parseBody fun(self: Request, type: string): Request Parse the request body according to the specified content type

local Request = {}
Request.__index = Request

local default_request = {
    _headers = {},
    _queries = {},
    _params = {},
    method = nil,
    path = nil,
    protocol = nil,
    body = "",
    hasBody = false,
    bodyType = nil,
    bodyParsed = false,
    keepAlive = false,
}

function Request.new(client)
    local instance = setmetatable({}, Request)
    for key, value in pairs(default_request) do
        instance[key] = value
    end
    instance._headers = {}
    for key, value in pairs(default_request._headers) do
        instance._headers[key] = value
    end
    if client then
        instance._client = client
    else
        error("Client failed to bind to request")
    end
    return instance
end

--- Get a header value or all headers
function Request:header(key)
    if not key then
        return self._headers
    end
    return self._headers[key]
end

--- Get a query value or all queries
function Request:query(key)
    if not key then
        return self._queries
    end
    return self._queries[key]
end

--- Get a parameter value or all parameters
function Request:param(key)
    if not key then
        return self._params
    end
    return self._params[key]
end

--- Unfinished
--- Parse the request body according to the specified content type
function Request:parseBody(type)
    local bodyType = {
        expected = self._headers["Content-Type"],
        asked = type
    }

    if bodyType.expected ~= bodyType.asked then
        print("Parsing body as " .. bodyType.asked .. " but expected " .. bodyType.expected)
    end

    return self
end

---Receive a line from the client socket
local function receiveLine(self)
    if not self._client then
        return nil, "Client not bound to request"
    end
    local line, err = self._client:receive()
    if line == "" or err then
        if err == "timeout" then
            return nil, "Timeout while reading line from client"
        end
        return nil, nil
    end
    return line, nil
end

---@return string|nil, string|nil, string|nil, table|nil The method, path, protocol, query parameters, or nil
local function extractPathParts(self)
    local headingLine, err = receiveLine(self)
    if not headingLine then
        return nil, "Failed to read request heading " .. (err or "")
    end
    local method, url, protocol = headingLine:match("(%S+)%s+(%S+)%s+(%S+)")
    if not method or not url or not protocol then
        return nil, "Failed to parse request heading: " .. headingLine
    end
    local path, query_string = url:match("([^?]+)%??(.*)")
    local queryTable = {}
    for key, value in query_string:gmatch("([^=]+)=([^&]+)&?") do
        queryTable[key] = value
    end
    self.method = method
    self.path = path
    self.protocol = protocol
    self._queries = queryTable
    return "true"
end

local function extractHeader(self)
    while true do
        local headerLine, err = receiveLine(self)
        if not headerLine or err then
            if err then
                print(err)
            end
            break
        end
        local key, value = headerLine:match("([^:]+):%s*(.+)")
        if not key then
            break
        end
        self._headers[key] = value
    end
end

local function extractBody(self)
    self.hasBody = true
    local contentLength = tonumber(self._headers["Content-Length"]) or 0
    if contentLength > 0 then
        local body, err = self._client:receive(contentLength)
        if err then
            self.hasBody = false
            self.body = nil
            return false
        else
            self.body = body
        end
    end
    return true
end

---Parse the incoming request
---@private
function Request:_parse()
    local parsing_ok, err = pcall(function()
        local ok, err = extractPathParts(self)
        if not ok then
            self:log("Failed to extract path parts: " .. err)
            return false
        end
        extractHeader(self)
        if self._headers["Content-Length"] then
            local ok = extractBody(self)
            if not ok then
                return false
            end
        end
        self.bodyParsed = true
        return true
    end)
    if not parsing_ok then
        return false
    end
    return true
end

return Request
