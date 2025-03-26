local inspector = require("inspect")

local inspect = function(msg, obj)
    local a = msg or ""
    print(a, inspector(obj))
end



return inspect
