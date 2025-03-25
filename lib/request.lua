---@class Request
---@field _headers table<string, string> The headers of the request
---@field method string The method of the request
---@field path string The path of the request
---@field protocol string The protocol of the request
---@field body string The body of the request
---@field hasBody boolean Whether the request has a body
---@field bodyType string The type of the body
---@field header fun(key: string|nil): table|string|nil Get a header value or all headers
---@field parseBody fun(type: string): nil Parse the request body according to the specified content type
---@field _build fun(client: table): boolean Build and parse the HTTP request from a client socket
---@field _bind fun(client: table): Request Bind the request to a client socket
local Request = {
    -- Private properties
    _headers = {},
    _queries = {},
    _params = {},

    method = nil,
    path = nil,
    protocol = nil,
    body = "",
    hasBody = false,
    bodyType = nil,

    ---Get a header value or all headers
    ---@param key string|nil The header key to retrieve, or nil to get all headers
    ---@return table|string|nil The header value, all headers, or nil if not found
    header = function(self, key)
        if not key then
            return self._headers
        end
        return self._headers[key]
    end,

    -- Get a query parameter value or all query parameters
    -- e.g /path?foo=bar&baz=qux
    query = function(self, key)
        if not key then
            return self._queries
        end
        return self._queries[key]
    end,

    -- Get a path parameter value or all path parameters
    -- e.g /path/:foo/:bar/:baz
    param = function(self, key)
        if not key then
            return self._params
        end
        return self._params[key]
    end,

    ---Parse the request body according to the specified content type
    ---@param type string The expected content type to parse as
    ---@return nil
    parseBody = function(self, type)
        local bodyType = {
            expected = self._headers["Content-Type"],
            asked = type
        }

        if bodyType.expected ~= bodyType.asked then
            print("Parsing body as " .. bodyType.asked .. " but expected " .. bodyType.expected)
        end
    end,

    ---Build and parse the HTTP request from a client socket
    ---@private
    ---@param client table The socket client to read the request from
    ---@return boolean success True if the request was successfully parsed
    _build = function(self, client)
        if not client then
            error("No client found")
            return false
        end

        function YieldLine()
            local line, err = client:receive()
            if not err then
                return line
            end
            return nil -- Explicitly return nil when there's an error
        end

        function YieldHeader(line)
            local key, value = line:match("([^:]+):%s*(.+)")
            if key and value then
                return key, value
            end
        end

        function ExtractPathParts(line)
            local method, url, protocol = line:match("(%S+)%s+(%S+)%s+(%S+)")
            local path, query = url:match("([^?]+)%??(.*)")
            local queryTable = {}
            for key, value in query:gmatch("([^=]+)=([^&]+)&?") do
                queryTable[key] = value
            end
            return method, path, protocol, queryTable
        end

        -- parse the first line of the request
        local line = YieldLine()
        if not line then
            return false -- Return early if we couldn't read the first line
        end

        local method, path, protocol, query = ExtractPathParts(line)
        self.method = method
        self.path = path
        self.protocol = protocol
        self._queries = query

        -- parse the headers
        while true do
            line = YieldLine()
            if not line or line == "" then
                break
            end
            local key, value = YieldHeader(line)
            self._headers[key] = value
        end

        -- store the body if it exists
        if self._headers["Content-Length"] then
            self.hasBody = true
            local contentLength = tonumber(self._headers["Content-Length"]) or 0
            if contentLength > 0 then
                local body, err = client:receive(contentLength)
                if not err then
                    self.body = body
                else
                    self.hasBody = false
                    self.body = nil
                end
            end
        end
    end

}

return Request
