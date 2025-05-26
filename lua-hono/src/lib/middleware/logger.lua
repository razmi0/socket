local logger = function()
    return function(c, next)
        print("<--", c.req.method)
        next()
        print("-->", c.res.status)
    end
end

return logger
