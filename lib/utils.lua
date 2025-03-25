local inspector = require("inspect")

local inspect = function(msg, obj)
    local msg = msg or ""
    print(msg, inspector(obj))
end

return inspect
