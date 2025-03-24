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

-- Store last modification times
local last_mod_times = {}

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

        local cmd = package.config:sub(1, 1) == "/" and SERVER_COMMAND .. " & echo $!" or
            "start /B " .. SERVER_COMMAND .. " && echo %ERRORLEVEL%"
        local handle = io.popen(cmd, "r")
        if not handle then
            print("Failed to start server:", SERVER_COMMAND)
            return
        end
        local pid = handle:read("*l")
        handle:close()
        prev_pid = pid
    end)

    if not success then
        print("Error restarting server:", err)
        socket.sleep(1)
    end
end

-- Initial scan
last_mod_times = scan_directories()

-- Print watched directories
print("Watching directories: " .. table.concat(WATCH_DIRS, " "))

start_server() -- Start the server initially

while true do
    local current_mod_times = scan_directories()

    -- Check for modified files
    for file, mod_time in pairs(current_mod_times) do
        if not last_mod_times[file] or last_mod_times[file] ~= mod_time then
            RELOADS = RELOADS + 1
            print(string.format("File modified: %-5s x%d", file:gsub("//", "/"), RELOADS))
            start_server()
            last_mod_times = current_mod_times
            break
        end
    end

    socket.sleep(CHECK_INTERVAL)
end
