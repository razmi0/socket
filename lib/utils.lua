local inspector = require("inspect")

local inspect = function(msg, obj)
    print(msg or "", inspector(obj))
end

return inspect
