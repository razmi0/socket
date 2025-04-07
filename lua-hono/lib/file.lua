local File = {}
File.__index = File

---@class File
---@field find fun(path: string): string Find a file
function File.new(root)
    local instance = setmetatable({}, File)
    instance.root = root
    return instance
end

-- need rework
---@param path string The path to find
---@return string|nil The content of the file
function File:find(path)
    if path:find("*") then
        local files = io.popen("ls " .. self.root .. path)

        if files then
            local result = {}
            for file in files:lines() do
                table.insert(result, file)
            end
            return result
        end
    end

    if self.root then
        path = self.root .. path
    end
    local file = io.open(path, "r")
    if not file then
        return nil
    end
    local content = file:read("*a")
    file:close()
    return content
end

return File
