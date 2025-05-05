local PATTERN_GROUPS = require("lib.trie-router.utils.pattern")

---@alias DynamicData { optionnal : true|nil, pattern : string|nil }
---@param str string
---@return string, "dynamic"|"static"|"wildcard", DynamicData, string
local function parse(str)
    if str == "*" then return str, "wildcard", {}, "*" end
    local dynamic, label, optionnal, pattern = str:match(PATTERN_GROUPS.complete)

    local data = {
        opt = (optionnal == "?") or nil,
        pattern = (pattern ~= "" and pattern) or nil
    }
    -- table.insert(data, (optionnal == "?") or nil)
    -- table.insert(data, (pattern ~= "" and pattern) or nil)
    if dynamic ~= ":" then return str, "static", data, label end
    return str, "dynamic", data, label
end

return parse
