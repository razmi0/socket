function HTTP400(ctx)
    ctx.res:setContentType("text/plain")
    ctx.res:setStatus(400)
    ctx.res:setBody("400 Bad Request")
    return ctx.res
end

return HTTP400
