local Debug_middleware = {}
Debug_middleware.__index = Debug_middleware

---@class Debug_middleware
---@field _next Debug_middleware|nil The next middleware in the chain
---@field register fun(self:Debug_middleware, handler: fun(ctx: Context)): string, function The identity and the registered middleware

---@param identity string The identity of the middleware
---@param handler (fun(ctx: Context, next: fun()): any )| table The handler or a pluggable instance of the middleware
---@return _ Debug_middleware The middleware instance
function Debug_middleware.register(identity, handler)
    local instance = setmetatable({}, Debug_middleware)
    instance.identity = identity
    instance.handler = handler
    instance.next = nil
    return instance
end

return Debug_middleware
