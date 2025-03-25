---@class Response
---@field __current string The current built response string
---@field __client table The socket client instance
---@field protocol string The protocol of the response
---@field status number The HTTP status code
---@field statusMessage string The HTTP status message
---@field body string The response body
---@field _headers table<string, string> The headers of the response
---@field header fun(key: string|nil): table|string|nil Get a header value or all headers
---@field _bind fun(client: table): Response Bind the response to a client socket
---@field setStatus fun(status: number): Response Set the HTTP status code and message
---@field setBody fun(body: string): Response Set the response body and update related headers
---@field addHeader fun(key: string, value: string): Response Add or update a response header
---@field setContentType fun(contentType: string): Response Set the Content-Type header
---@field send fun(): nil Send the response to the client
---@field _build fun(): nil Build the complete HTTP response string
local Response = {
    -- Private properties
    __current = "", -- Current built response string
    __client = nil, -- Socket client instance
    -- Protected properties
    protocol = "HTTP/1.1",
    status = 200,
    statusMessage = "OK",
    body = "",
    _headers = {
        ["Content-Type"] = "application/json",
        ["Content-Length"] = 0,
        ["Connection"] = "close",
        ["Server"] = "Raz",
        ["Date"] = os.date("%a, %d %b %Y %H:%M:%S GMT"),
        ["Last-Modified"] = os.date("%a, %d %b %Y %H:%M:%S GMT")
    },

    ---Get a header value or all headers
    ---@param key string|nil The header key to retrieve, or nil to get all headers
    ---@return table|string|nil The header value, all headers, or nil if not found
    header = function(self, key)
        if not key then
            return self._headers
        end
        return self._headers[key]
    end,

    ---Set the client socket for the response
    ---@param client table The socket client instance
    ---@return Response self The response instance for method chaining
    _bind = function(self, client)
        self.__client = client
        return self
    end,

    ---Set the HTTP status code and message
    ---@param status number The HTTP status code (e.g., 200, 404, 500)
    ---@return Response self The response instance for method chaining
    setStatus = function(self, status)
        local codes = {
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

        self.status = status
        self.statusMessage = codes[status] or "Unknown"
        return self
    end,

    ---Set the response body and update related headers
    ---@param body string The response body content
    ---@return Response self The response instance for method chaining
    setBody = function(self, body)
        self.body = body
        self._headers["Content-Length"] = #body
        self._headers["Last-Modified"] = os.date("%a, %d %b %Y %H:%M:%S GMT")
        return self
    end,

    ---Add or update a response header
    ---@param key string The header key
    ---@param value string The header value
    ---@return Response self The response instance for method chaining
    addHeader = function(self, key, value)
        self._headers[key] = value
        return self
    end,

    ---Set the Content-Type header
    ---@param contentType string The content type (e.g., "application/json", "text/html")
    ---@return Response self The response instance for method chaining
    setContentType = function(self, contentType)
        self._headers["Content-Type"] = contentType
        return self
    end,

    ---Build and send the response to the client
    ---@return nil
    send = function(self)
        self:_build()
        self.__client:send(self.__current)
    end,

    ---Build the complete HTTP response string
    ---@private
    ---@return nil
    _build = function(self)
        if not self.__client then
            error("No client found")
            return
        end

        local heading = self.protocol .. " " .. self.status .. " " .. self.statusMessage .. "\r\n"
        local headers = ""
        for key, value in pairs(self._headers) do
            if value ~= nil then
                headers = headers .. key .. ": " .. value .. "\r\n"
            end
        end

        -- Build the response
        self.__current = heading .. headers .. "\r\n" .. self.body
    end
}

return Response
