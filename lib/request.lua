local Request = {
    -- Private properties
    _headers = {},
    method = nil,
    path = nil,
    protocol = nil,
    body = "",
    hasBody = false,
    bodyType = nil,

    header = function(self, key)
        if not key then
            return self._headers
        end
        return self._headers[key]
    end,

    parseBody = function(self, type)
        local bodyType = {
            expected = self._headers["Content-Type"],
            asked = type,
        }

        if bodyType.expected ~= bodyType.asked then
            print("Parsing body as " .. bodyType.asked .. " but expected " .. bodyType.expected)
        end
    end,

    -- Protected methods
    _build = function(self, client)
        if not client then
            error("No client found")
            return
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

        -- parse the first line of the request
        local line = YieldLine()
        if not line then
            return false -- Return early if we couldn't read the first line
        end

        self.method, self.path, self.protocol = line:match("(%S+)%s+(%S+)%s+(%S+)")

        -- parse the headers
        while true do
            line = YieldLine()
            if not line or line == "" then break end
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
    end,

}

return Request
