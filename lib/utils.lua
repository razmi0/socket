local inspect = require("inspect")


-- Colors for terminal ( not exported )

local colors = {
    red = "\27[31m",
    green = "\27[32m",
    yellow = "\27[33m",
    blue = "\27[34m",
    magenta = "\27[35m",
    cyan = "\27[36m",
    reset = "\27[0m"
}

local Colorize = {}
Colorize.__index = Colorize

function Colorize.new(active)
    local instance = setmetatable({
    }, Colorize)
    instance._active = active
    instance._colors = colors
    return instance
end

function Colorize:colorize(text, color)
    if self._active then
        return self._colors[color] .. text .. self._colors.reset
    end
    return text
end

-- Inspect ( exported )

local Inspect = {}
Inspect.__index = Inspect

---@param config? table<{trace: boolean, clean: boolean, color: boolean, verbose: boolean}>
function Inspect.new(config)
    local instance = setmetatable({}, Inspect)
    instance._stack = {}
    local _config = {
        trace = true,
        clean = true,
        color = true,
        verbose = false,
    }
    for k, v in pairs(config or {}) do
        _config[k] = v
    end
    instance._config = _config
    instance._C = Colorize.new(_config.color)
    return instance
end

function Inspect:setVerbose(flag)
    self._config.verbose = flag
end

function Inspect:push(obj, is_err)
    local skip_lvls = 2 -- self call and push call does not print
    local trace = debug.traceback(nil, skip_lvls)
    local timestamp = os.date("%H:%M:%S:")

    if self._config.trace then
        table.insert(self._stack,
            { timestamp, obj, self:_remove_line(trace, self:_count_lines(trace)), is_err })
    else
        table.insert(self._stack, { timestamp, obj, nil, is_err })
    end
end

function Inspect:_add_new_line()
    if self._config.trace then
        return "\n"
    end
    return ""
end

function Inspect:print()
    if not self._config.verbose then
        return
    end
    for _, obj in ipairs(self._stack) do
        local time = self._C:colorize(obj[1], "cyan") or ""
        local msg = obj[2] or ""
        local trace = obj[3] or ""
        local is_err = obj[4] or false

        if is_err then
            msg = self._C:colorize(inspect(msg, { newline = '' }), "red")
        else
            msg = self._C:colorize(inspect(msg, { newline = '' }), "yellow")
        end

        local formatted_trace = self._C:colorize(trace:sub(1, 15), "blue") .. "\t" .. trace:sub(16)

        local output = time .. " : " .. msg .. self:_add_new_line() .. formatted_trace .. self:_add_new_line()

        print(output)

        if self._config.clean then
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
