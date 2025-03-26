local cjson = require "cjson"

local Context = {
    create = function(self, request, response)
        return {
            req = request,
            res = response,
            -- Add a header to the response
            -- @param key string The header key
            -- @param value string The header value
            header = function(key, value)
                response:addHeader(key, value)
                return response
            end,
            -- Set the body of the response
            -- @param body string The body of the response
            -- @param status number|nil The status code of the response
            -- @param headers table|nil The headers of the response
            body = function(body, status, headers)
                response:setBody(body)
                if status then
                    response:setStatus(status)
                end
                if headers then
                    for key, value in pairs(headers) do
                        response:addHeader(key, value)
                    end
                end
                return response
            end,

            text = function(text)
                response:setStatus(200)
                response:setBody(text)
                response:addHeader("Content-Type", "text/plain")
                return response
            end,

            json = function(table)
                response:setStatus(200)
                response:setBody(cjson.encode(table))
                response:addHeader("Content-Type", "application/json")
                return response
            end,

            html = function(html)
                response:setStatus(200)
                response:setBody(html)
                response:addHeader("Content-Type", "text/html")
                return response
            end,

            -- Set the status code of the response
            -- @param status number The status code of the response
            status = function(status)
                response:setStatus(status)
                return response
            end,

            notFound = function()
                response:setStatus(404)
                response:setBody("Not Found")
                response:addHeader("Content-Type", "text/plain")
                return response
            end,

            -- Store key-value pairs in the context for use in request handlers
            -- @param key string The key to set
            -- @param value string The value to set
            kvSpace = {},
            set = function(key, value)
                self.kvSpace[key] = value
            end,
            -- Get a key-value pair from the context
            get = function(key)
                return self.kvSpace[key]
            end

        }
    end
}

return Context
