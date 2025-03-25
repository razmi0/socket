local socket = require("socket")
local Request = require("lib/request")
local Response = require("lib/response")
local inspector = require("inspect")

local inspect = function(msg, obj)
    print(msg, inspector(obj))
end

local App = {
    -- Protected properties
    _host = "localhost",
    _port = 0,
    _server = nil,
    _request = Request,
    _response = Response,
    _routes = {
        GET = {},
        POST = {},
        find = function(self)
            return self._routes[self._request.method][self._request.path]
        end
    },


    -- Public methods
    start = function(self, base)
        local host = base.host or self._host
        local port = base.port or self._port

        self._server = assert(socket.bind(host, port), "Failed to bind server!")
        print("listening on http://" .. host .. ":" .. port)

        while true do
            local client = self._server:accept()
            client:settimeout(0.5)

            -- bad dependency injection
            self._request:_build(client)
            self._response:setClient(client)

            -- Find route => User callback() --
            local route = self._routes.find(self)
            route({ req = self._request, res = self._response })

            client:close()

            -- Print some debug info
            print("<--", self._request.method, self._request.path)
            print("-->", self._response.status, self._response:header("Content-Type"))
        end
    end,

    get = function(self, path, callback)
        self._routes.GET[path] = callback
    end,

    post = function(self, path, callback)
        self._routes.POST[path] = callback
    end,


}

return App
