local HTTP404 = require("lib.http-exception.not-found")
local HTTP405 = require("lib.http-exception.method-not-allowed")

local function is_response(obj)
    local mt = getmetatable(obj)
    return mt and mt.__name == "Response"
end

local function compose(mws, ctx, match)
    local hs = {}
    local executed_counter = 0

    for _, mw in ipairs(mws) do
        for _, h in ipairs(mw.handlers[1]) do
            hs[#hs + 1] = h
        end
    end

    -- err 500 or 400
    if ctx._err_handler then
        hs[#hs] = ctx._err_handler
    end

    local function dispatch(i)
        if i > #hs then
            -- all mw executed
            -- no response set
            if not ctx._finalized and match then
                HTTP405(ctx)
                ctx._finalized = true
            else
                HTTP404(ctx)
                ctx._finalized = true
            end
            return
        end

        local h = hs[i]

        local called = false
        local function next()
            if called or ctx._finalized then return end
            called = true
            dispatch(i + 1)
        end

        local ok, result = pcall(function()
            executed_counter = executed_counter + 1
            return h(ctx, next)
        end)

        if not ok then
            print(result)
            ctx._err_handler = HTTP500
            hs[#hs] = ctx._err_handler
        end

        if ok and is_response(result) then
            ctx._finalized = true
        end
    end

    dispatch(1)

    if executed_counter < #hs then
        print("\27[38;5;208m[WARN]\27[0m : Did you forget to call next() in a middleware ?")
    end
    if not ctx._finalized then
        print("\27[38;5;208m[WARN]\27[0m : Context is not finalized ?")
    end
end


return compose
