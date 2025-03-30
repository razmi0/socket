local inspect = require("inspect")
local socket = require("socket")

local colors = {
    red = "\27[31m",
    green = "\27[32m",
    yellow = "\27[33m",
    blue = "\27[34m",
    magenta = "\27[35m",
    cyan = "\27[36m",
    reset = "\27[0m"
}

-- local inspect = function(msg, obj)
--     local a = msg or ""
--     print(a, inspector(obj))
-- end

local Inspect = {}
Inspect.__index = Inspect

function Inspect.new()
    local instance = setmetatable({}, Inspect)
    instance._stack = {}
    return instance
end

function Inspect:push(obj)
    local skip_lvls = 2 -- self call and push call does not print
    local trace = debug.traceback(nil, skip_lvls)
    local now = socket.gettime()
    local seconds = math.floor(now)                     -- Get the integer part (full seconds)
    local milliseconds = math.floor((now - seconds) * 1000) -- Get the milliseconds part
    local timestamp = os.date("%H:%M:%S:") .. string.format("%03d", milliseconds)
    table.insert(self._stack,
        { timestamp, obj, self:_remove_line(trace, self:_count_lines(trace)) })
end

function Inspect:print(clean)
    for _, obj in ipairs(self._stack) do
        local time = obj[1]
        local msg = obj[2]
        local trace = obj[3]

        print(
            colors.cyan .. time .. colors.reset .. " : "
            .. colors.yellow .. inspect(msg, { newline = '' }) .. colors.reset .. "\n"
            .. colors.blue .. trace:sub(1, 15) .. colors.reset
            .. "\t" .. trace:sub(16) .. "\n"
        )

        if clean then
            self._stack = {}
        end
    end
end

function Inspect:_count_lines(stack_trace)
    local count = 0
    for _ in stack_trace:gmatch("[^\n]+") do
        count = count + 1
    end
    return count
end

function Inspect:_remove_line(stack_trace, line_number)
    local lines = {}
    for line in stack_trace:gmatch("[^\n]+") do
        table.insert(lines, line)
    end
    table.remove(lines, line_number)
    return table.concat(lines, "\n")
end

return Inspect
