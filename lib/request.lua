local Request = {
    -- Private properties
    __client = nil,
    __headers = {},
    __method = nil,
    __path = nil,
    __protocol = nil,
    __body = "",
    __hasBody = false,
    __bodyType = nil,

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

    getBody = function(self)
        return self.__body
    end,

    hasBody = function(self)
        return self.__hasBody
    end,

    getBodyType = function(self)
        return self.__bodyType
    end,

    parseBody = function(self, type)
        local bodyType = type or self.__bodyType
    end,


    -- Protected methods
    _build = function(self)
        function YieldLine()
            local line, err = self.__client:receive()
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

        -- parse the first line of the request
        local line = YieldLine()
        if not line then
            return false -- Return early if we couldn't read the first line
        end

        self.__method, self.__path, self.__protocol = line:match("(%S+)%s+(%S+)%s+(%S+)")

        -- parse the headers
        while true do
            line = YieldLine()
            if not line or line == "" then break end
            local key, value = YieldHeader(line)
            self.__headers[key] = value
        end

        -- store the body if it exists
        if self.__headers["Content-Length"] then
            self.__hasBody = true
            local contentLength = tonumber(self.__headers["Content-Length"]) or 0
            if contentLength > 0 then
                local body, err = self.__client:receive(contentLength)
                if not err then
                    self.__body = body
                else
                    self.__hasBody = false
                    self.__body = nil
                end
            end
        end

        -- if self.__method == "POST" or self.__method == "PUT" or self.__method == "PATCH" then
        --     print(self.__body)

        --     for key, value in pairs(self.__headers) do
        --         print(key, value)
        --     end
        -- end

        -- determine the body type
        if self.__headers["Content-Type"] then
            -- local mimesTypes = {
            --     ["application/json"] = "json",
            --     ["application/xml"] = "xml",
            --     ["text/plain"] = "text",
            --     ["text/html"] = "html",
            --     ["text/css"] = "css",
            --     ["text/javascript"] = "javascript",
            -- }

            -- self.__bodyType = self.__headers["Content-Type"]
        end
    end,

}

return Request
