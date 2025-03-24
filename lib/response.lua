local Response = {
    -- Private properties
    __client = nil,
    __current = "",

    -- Protected properties
    _protocol = "HTTP/1.1",
    _status = 200,
    _statusMessage = "OK",
    _headers = {
        ["Content-Type"] = "application/json",
        ["Content-Length"] = 0,
        ["Connection"] = "close",
        ["Server"] = "Raz",
        ["Date"] = os.date("%a, %d %b %Y %H:%M:%S GMT"),
        ["Last-Modified"] = os.date("%a, %d %b %Y %H:%M:%S GMT"),
    },
    _body = "",

    getHeader = function(self, key)
        return self._headers[key]
    end,

    getStatus = function(self)
        return self._status
    end,

    getStatusMessage = function(self)
        return self._statusMessage
    end,

    -- Public methods
    setClient = function(self, client)
        self.__client = client
        return self
    end,

    setStatus = function(self, status, statusMessage)
        self._status = status
        self._statusMessage = statusMessage
        return self
    end,

    setBody = function(self, body)
        self._body = body
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
        local heading = self._protocol .. " " .. self._status .. " " .. self._statusMessage .. "\r\n"
        local headers = ""
        for key, value in pairs(self._headers) do
            if value ~= nil then
                headers = headers .. key .. ": " .. value .. "\r\n"
            end
        end
        self.__current = heading .. headers .. "\r\n" .. self._body
    end,
}

return Response
