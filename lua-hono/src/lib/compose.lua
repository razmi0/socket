local inspect = require("inspect")

local function compose(mws, ctx)
    local hs, result = {}, nil

    for _, mw in ipairs(mws) do
        for _, h in ipairs(mw.handlers[1]) do
            hs[#hs + 1] = h
        end
    end

    local function is_response(obj)
        local mt = getmetatable(obj)
        return mt and mt.__name == "Response"
    end

    local function dispatch(i)
        if i > #hs then return end
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

    if not ctx._finalized then
        print("no response handler, do stuff here")
    end
end


return compose
