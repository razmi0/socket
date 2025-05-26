function HTTP500(ctx)
    ctx.res:setContentType("text/plain")
    ctx.res:setStatus(500)
    ctx.res:setBody("500 Internal Server Error")
    return ctx.res
end

return HTTP500
