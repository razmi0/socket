local lfs = require("lfs")
local socket = require("socket")

local CHECK_INTERVAL = 1               -- Time in seconds between checks
local SERVER_COMMAND = "lua index.lua" -- Change this
local prev_pid = nil
local WATCH_DIRS = {                   -- Directories to watch
    "./",
    "./lib"
}
local RELOADS = 0
local server_output_co = nil

-- Store last modification times
local last_mod_times = {}

local COLORS = {
    reset = "\27[0m",
    -- Regular colors
    red = "\27[31m",
    green = "\27[32m",
    yellow = "\27[33m",
    blue = "\27[34m",
    magenta = "\27[35m",
    cyan = "\27[36m",
    grey = "\27[90m",
    -- Bright/bold colors
    bright_red = "\27[91m",
    bright_green = "\27[92m",
    bright_blue = "\27[94m",
    bright_magenta = "\27[95m",
    bright_cyan = "\27[96m",
}

-- Helper function to wrap text in color
local function colorize(color, text)
    return COLORS[color] .. text .. COLORS.reset
end

-- Function to get file modification times
local function scan_directories()
    local files = {}
    for _, dir in ipairs(WATCH_DIRS) do
        for file in lfs.dir(dir) do
            if file ~= "." and file ~= ".." then
                local full_path = (dir .. "/" .. file):gsub("//", "/")
                local attr = lfs.attributes(full_path)
                if attr and attr.mode == "file" then
                    files[full_path] = attr.modification
                end
            end
        end
    end
    return files
end

-- Function to kill the previous server process
local function stop_previous_process()
    if prev_pid then
        local kill_cmd = package.config:sub(1, 1) == "/" and "kill -9 " or "taskkill /F /PID "
        os.execute(kill_cmd .. prev_pid)
        prev_pid = nil
        socket.sleep(0.5)
    end
end

-- Function to start the server
local function start_server()
    local success, err = pcall(function()
        stop_previous_process()

        local cmd
        if package.config:sub(1, 1) == "/" then
            -- For Unix-like systems
            cmd = SERVER_COMMAND .. " 2>&1 & echo $!"
        else
            -- For Windows
            cmd = "start /B " .. SERVER_COMMAND .. " 2>&1 && echo %ERRORLEVEL%"
        end

        local handle = io.popen(cmd, "r")
        if not handle then
            print("Failed to start server:", SERVER_COMMAND)
            return
        end

        -- Read the PID from the first line
        local pid = handle:read("*l")
        prev_pid = pid

        -- Kill previous coroutine if it exists
        if server_output_co then
            coroutine.close(server_output_co)
        end

        -- Create new coroutine for reading server output
        server_output_co = coroutine.create(function()
            while true do
                local line = handle:read("*l")
                if not line then break end
                print(colorize("bright_blue", "[Server] ") .. line)
                coroutine.yield()
            end
            handle:close()
        end)

        -- Resume the coroutine to start it
        coroutine.resume(server_output_co)
    end)

    if not success then
        print("Error restarting server:", err)
        socket.sleep(1)
    end
end


-- Initial scan
last_mod_times = scan_directories()

print(colorize("cyan", "Now watching.."))

start_server() -- Start the server initially


while true do
    local current_mod_times = scan_directories()

    for file, mod_time in pairs(current_mod_times) do
        if server_output_co and coroutine.status(server_output_co) ~= "dead" then
            coroutine.resume(server_output_co)
        end
        if not last_mod_times[file] or last_mod_times[file] ~= mod_time then
            start_server()
            RELOADS = RELOADS + 1
            print(
                colorize("grey", string.format("File modified: %-5s", file:gsub("//", "/"))) ..
                colorize("yellow", " x" .. RELOADS)
            )

            last_mod_times = current_mod_times
            break
        end
    end

    socket.sleep(CHECK_INTERVAL)
end
