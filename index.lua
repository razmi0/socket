local Raz = require("lib/server")



local title = "Hello, world!"

Raz:start(function(req, res)
    res:setBody("<h1>" .. title .. "</h1>"):send()
end, {
    host = "localhost",
    port = 8080,
})
