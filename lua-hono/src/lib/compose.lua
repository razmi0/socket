local inspect = require("inspect")

local function compose(mws, ctx)
    print(inspect(mws))
end

return compose

-- local handler = chain[#chain]
--     ---@type Response
--     local response = context.res
--     local function dispatch(i)
--         if i > #chain then return nil end
--         if i == #chain then
--             local next = function()
--                 print("Did you make a next() call in an handler ?")
--                 return
--             end
--             -- Execute final handler and store the response
--             response = handler(context, next)
--         else
--             local nextCalled = false
--             local function next()
--                 if nextCalled then
--                     print("Did you called next() multiple times ?")
--                     return
--                 end
--                 nextCalled = true
--                 dispatch(i + 1)
--             end
--             -- Execute middleware and ignore its return value
--             local r = chain[i](context, next)
--         end
--     end

--     dispatch(1)
--     return response
