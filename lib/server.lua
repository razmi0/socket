local socket = require("socket")
local Request = require("lib/request")
local Response = require("lib/response")

local Raz = {
    -- Protected properties
    _host = "localhost",
    _port = 8080,
    _server = nil,
    _request = Request,
    _response = Response,

    -- Public methods
    start = function(self, callback, base)
        local host = base.host or self._host
        local port = base.port or self._port

        self._server = assert(socket.bind(host, port), "Failed to bind server!")
        print("Server running on http://" .. host .. ":" .. port)

        while true do
            local client = self._server:accept()
            client:settimeout(1)

            -- Set the client socket in the request object | Request:_build() is called in the start() method
            self._request:setClient(client):_build()
            -- Set the client socket in the response object | Response:_build() is called in the send() method
            self._response:setClient(client)

            callback(self._request, self._response)

            client:close()
        end
    end,
}

return Raz


-- Build a simple HTTP response
-- local response = "HTTP/1.1 200 OK\r\n"
--     .. "Content-Type: text/html\r\n"
--     .. "Content-Length: 13\r\n"
--     .. "\r\n"
--     .. "Hello, world!"
