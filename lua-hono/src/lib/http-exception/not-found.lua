function HTTP404(ctx)
    ctx.res:setContentType("text/plain")
    ctx.res:setStatus(404)
    ctx.res:setBody("404 Not Found")
    return ctx.res
end

return HTTP404
