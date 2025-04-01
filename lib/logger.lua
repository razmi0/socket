local inspect = require("inspect")
local Debug_middleware = require("lib.debug-middleware")


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

---@class LogOptions
---@field prefix string? The prefix to use for the log
---@field is_err boolean? Whether the log is an error

---@param obj table The object to log
---@param options? LogOptions The options to use for the log
function Inspect:push(obj, options)
    local prefix = options and options.prefix or ""
    local is_err = options and options.is_err or false
    local skip_lvls = 2 -- self call and push call are not printed
    local trace = debug.traceback(nil, skip_lvls)
    local timestamp = os.date("%H:%M:%S:")

    if self._config.trace then
        table.insert(self._stack,
            { timestamp, prefix, obj, self:_remove_line(trace, self:_count_lines(trace)), is_err })
    else
        table.insert(self._stack, { timestamp, prefix, obj, nil, is_err })
    end
end

function Inspect:_add_new_line()
    if self._config.trace then
        return "\n"
    end
    return ""
end

---@class PrintOptions
---@field newline string? The newline character to use
---@field indent string? The indent character to use

---@param options? PrintOptions The options to use for the print function
function Inspect:print(options)
    if not self._config.verbose then
        return
    end

    local newline = options and options.newline or "\n"
    local indent = options and options.indent or "  "

    for _, obj in ipairs(self._stack) do
        local time = self._C:colorize(obj[1], "cyan") or ""
        local prefix = obj[2] or ""
        local msg = obj[3] or ""
        local trace = obj[4] or ""
        local is_err = obj[5] or false

        if is_err then
            msg = self._C:colorize(inspect(msg, { newline = newline, indent = indent }), "red")
        else
            msg = self._C:colorize(inspect(msg, { newline = newline, indent = indent }), "yellow")
        end

        local formatted_trace = self._C:colorize(trace:sub(1, 15), "blue") .. "\t" .. trace:sub(16)

        local output = time ..
            " : " .. prefix .. " : " .. msg .. self:_add_new_line() .. formatted_trace .. self:_add_new_line()

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

---@param config? table<{trace: boolean, clean: boolean, color: boolean, verbose: boolean}>
---@return Debug_middleware The logger instance registered as a middleware
local logger = function(config)
    return Debug_middleware.register("logger", Inspect.new(config))
end

return logger
