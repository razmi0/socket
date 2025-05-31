local inspect = require("inspect")
local HTTP404 = require("lib.http-exception.not-found")
local HTTP405 = require("lib.http-exception.method-not-allowed")

local function compose(mws, ctx, match)
    local hs, result = {}, nil

    for _, mw in ipairs(mws) do
        for _, h in ipairs(mw.handlers[1]) do
            hs[#hs + 1] = h
        end
    end

    -- err 500 or 400
    if ctx._err_handler then
        hs[#hs] = ctx._err_handler
    end

    local function is_response(obj)
        local mt = getmetatable(obj)
        return mt and mt.__name == "Response"
    end

    local function dispatch(i)
        if i > #hs then
            if not ctx._finalized then
                if match then
                    HTTP405(ctx)
                else
                    HTTP404(ctx)
                end
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

        result = h(ctx, next)
        if is_response(result) then
            ctx._finalized = true
        end
    end

    dispatch(1)
end


return compose
