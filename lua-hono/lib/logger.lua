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
    dark_grey = "\27[90m",
    light_grey = "\27[37m",
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
---@field escape boolean? Whether to escape the log

---@param obj table The object to log
---@param options? LogOptions The options to use for the log
function Inspect:push(obj, options)
    local prefix = options and options.prefix or ""
    local is_err = options and options.is_err or false
    local escape = options and options.escape or false
    local timestamp = self:getTimestamp()

    if escape then
        table.insert(self._stack, { timestamp .. "\n", obj })
        return
    end

    local skip_lvls = 2 -- self call and push call are not printed
    local trace = debug.traceback(nil, skip_lvls)

    if self._config.trace then
        table.insert(
            self._stack,
            { timestamp, prefix, obj, self:_remove_line(trace, self:_count_lines(trace)), is_err }
        )
    else
        table.insert(
            self._stack,
            { timestamp, prefix, obj, nil, is_err }
        )
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
        local time = obj[1] or ""
        local prefix = obj[2] or ""
        local msg = obj[3] or ""
        local trace = obj[4] or ""
        local is_err = obj[5] or false

        if msg ~= "" then
            if is_err then
                msg = self._C:colorize(inspect(msg, { newline = newline, indent = indent }), "red")
            else
                msg = self._C:colorize(inspect(msg, { newline = newline, indent = indent }), "yellow")
            end
        end

        local formatted_trace = self._C:colorize(trace:sub(1, 15), "blue") .. "\t" .. trace:sub(16)

        local output = time ..
            " " .. prefix .. " " .. msg .. self:_add_new_line() .. formatted_trace .. self:_add_new_line()

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

function Inspect:routes(routes)
    local output = {}
    local methods = { "GET", "POST", "PUT", "DELETE" }

    local separator = function(method)
        local divider = "================"
        return self._C:colorize(method, "light_grey")
    end

    local create_line = function(functions, path, maxLen)
        -- Using string.format to pad the path to maxLen characters.
        return string.format("|    %-"
            .. maxLen .. "s : [ %s ]",
            path, table.concat(functions, ", ")
        )
    end

    local handlers_to_array = function(handlers)
        local functions = {}
        for i, _ in ipairs(handlers) do
            if i == #handlers then
                table.insert(functions, "handler")
            else
                table.insert(functions, "middleware" .. i)
            end
        end
        return functions
    end


    -- Helper to build the full path for a 'try' route.
    local function build_full_try_path(try)
        local path = "/" .. try.value
        local next = try.next
        while true do
            path = path .. "/" .. next.value
            if next.done or next.value == nil then
                break
            end
            next = next.next
        end
        return path
    end

    -- Helper to calculate the maximum length of all paths.
    local function calculate_max_length(indexed, tries)
        local maxLen = 0
        for path, _ in pairs(indexed) do
            if #path > maxLen then
                maxLen = #path
            end
        end
        for _, try in ipairs(tries) do
            local tryPath = build_full_try_path(try)
            if #tryPath > maxLen then
                maxLen = #tryPath
            end
        end
        return maxLen
    end

    -- Helper to process indexed routes.
    local function process_indexed(indexed, maxLen)
        local output = {}
        for path, handlers in pairs(indexed) do
            local functions = handlers_to_array(handlers)
            local line = create_line(functions, path, maxLen)
            table.insert(output, line)
        end
        return output
    end

    -- Helper to process try routes.
    local function process_tries(tries, maxLen)
        local output = {}
        for _, try in ipairs(tries) do
            local path = build_full_try_path(try)
            local handlers = try[1].handlers
            local functions = handlers_to_array(handlers)
            local line = create_line(functions, path, maxLen)
            table.insert(output, line)
        end
        return output
    end

    for method, routeData in pairs(routes) do
        -- Only process if the method is one of our specified methods.
        local total_method_routes = 0
        if table.concat(methods):find(method) then
            local indexed = routeData.indexed
            local tries = routeData.tries


            local maxLen = calculate_max_length(indexed, tries)

            -- Process both indexed and try routes.
            local indexedOutput = process_indexed(indexed, maxLen)
            local triesOutput = process_tries(tries, maxLen)
            total_method_routes = #indexedOutput + #triesOutput
            table.insert(output, separator(method .. " (" .. total_method_routes .. ")"))
            for _, line in ipairs(indexedOutput) do
                table.insert(output, line)
            end
            for _, line in ipairs(triesOutput) do
                table.insert(output, line)
            end
        end
    end

    table.insert(self._stack, { self:getTimestamp() .. "\n", table.concat(output, "\n") })
end

function Inspect:getTimestamp()
    return self._C:colorize(os.date("%H:%M:%S"), "cyan")
end

---@param config? table<{trace: boolean, clean: boolean, color: boolean, verbose: boolean}>
---@return Debug_middleware The logger instance registered as a middleware
local logger = function(config)
    return Debug_middleware.register("logger", Inspect.new(config))
end

return logger
