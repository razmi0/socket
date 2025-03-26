local cjson = require "cjson"

-- Context object for request handlers
-- has a lot of helper functions & syntactic sugar / makes the code easier
-- @field req Request The request object
-- @field res Response The response object
-- @field header fun(key: string, value: string): Response Add a header to the response
-- @field body fun(body: string, status: number?, headers: table?): Response Set the body of the response
-- @field status fun(status: number): Response Set the status code of the response
-- @field notFound fun(): Response Set the status code to 404 and the body to "Not Found"
local Context = {
    create = function(self, request, response)
        return {
            req = request,
            res = response,
            -- Add a header to the response
            -- @param key string The header key
            -- @param value string The header value
            -- @return Response The response object
            header = function(key, value)
                response:addHeader(key, value)
                return response
            end,
            -- Set the body of the response
            -- @param body string The body of the response
            -- @param status number|nil The status code of the response
            -- @param headers table|nil The headers of the response
            -- @return Response The response object
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

            -- Set the body of the response to a text string
            -- @param text string The text to set the body to
            -- @return Response The response object
            text = function(text)
                response:setStatus(200)
                response:setBody(text)
                response:addHeader("Content-Type", "text/plain")
                return response
            end,

            -- Set the body of the response to a JSON object
            -- @param table table The table to encode to JSON
            -- @return Response The response object
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
            -- @return Response The response object
            status = function(status)
                response:setStatus(status)
                return response
            end,

            -- Set the status code to 404 and the body to "Not Found"
            -- @return Response The response object
            notFound = function()
                response:setStatus(404)
                response:setBody("Not Found")
                response:addHeader("Content-Type", "text/plain")
                return response
            end,

            -- Key-value store for request handlers
            kvSpace = {},
            -- Store key-value pairs in the context for use in request handlers
            -- @param key string The key to set
            -- @param value string The value to set
            set = function(key, value)
                self.kvSpace[key] = value
            end,
            -- Get a key-value pair from the context
            -- @param key string The key to get
            -- @return string The value of the key
            get = function(key)
                return self.kvSpace[key]
            end

        }
    end
}

return Context
