local function colorize(text, colorCode)
    return string.format("\27[%sm%s\27[0m", colorCode, text)
end

local function pad(str, len)
    return str .. "\27[0m" .. string.rep(" ", math.max(0, len - #str))
end

local logger = function()
    return function(c, next)
        local method = c.req.method or "UNKNOWN"
        local path = c.req.path or "/"
        local startTime = os.clock()

        print(
            colorize("<--", "1;30"),
            colorize(pad(method, 6), "4;37"),
            colorize(path, "0;37")
        )

        next()

        local status = c.res.status or "?"
        local time = string.format("%.2fms", (os.clock() - startTime) * 1000)
        local statusColor = (status >= 500 and "1;31") or
            (status >= 400 and "1;33") or
            (status >= 300 and "1;35") or
            (status >= 200 and "1;32") or
            "0;37"

        print(
            colorize("-->", "1;30"),
            colorize(tostring(status), statusColor),
            colorize(time, "2;90")
        )
    end
end

return logger
