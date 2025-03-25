local Response = {
    -- Private properties
    __current = "",
    __client = nil,
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
        ["Last-Modified"] = os.date("%a, %d %b %Y %H:%M:%S GMT"),
    },

    header = function(self, key)
        if not key then
            return self._headers
        end
        return self._headers[key]
    end,

    -- Public methods

    setClient = function(self, client)
        self.__client = client
        return self
    end,

    setStatus = function(self, status)
        local codes = {
            [200] = "OK",
            [404] = "Not Found",
            [500] = "Internal Server Error",
        }

        self.status = status
        self.statusMessage = codes[status] or "Unknown"
        return self
    end,

    setBody = function(self, body)
        self.body = body
        self._headers["Content-Length"] = #body
        self._headers["Last-Modified"] = os.date("%a, %d %b %Y %H:%M:%S GMT")
        return self
    end,

    addHeader = function(self, key, value)
        self._headers[key] = value
        return self
    end,

    setContentType = function(self, contentType)
        self._headers["Content-Type"] = contentType
        return self
    end,

    send = function(self)
        self:_build()
        self.__client:send(self.__current)
    end,

    -- Protected methods
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
    end,
}

return Response
