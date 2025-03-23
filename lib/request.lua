local Request = {
    -- Private properties
    __client = nil,
    __headers = {},
    __method = nil,
    __path = nil,
    __protocol = nil,

    -- Public methods
    setClient = function(self, client)
        self.__client = client
        return self
    end,

    getHeaders = function(self)
        return self.__headers
    end,

    getHeader = function(self, key)
        return self.__headers[key]
    end,

    getMethod = function(self)
        return self.__method
    end,

    getPath = function(self)
        return self.__path
    end,

    getProtocol = function(self)
        return self.__protocol
    end,

    -- Protected methods
    _build = function(self)
        local line, err = self.__client:receive()
        if not err then
            self.__method, self.__path, self.__protocol = line:match("(%S+)%s+(%S+)%s+(%S+)")

            line, err = self.__client:receive()
            while line and line ~= "" do
                local key, value = line:match("([^:]+):%s*(.+)")
                if key and value then
                    self.__headers[key] = value
                end
                line, err = self.__client:receive()
            end
        end
    end,

}

return Request
