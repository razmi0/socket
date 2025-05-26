function HTTP405(ctx)
    ctx.res:setContentType("text/plain")
    ctx.res:setStatus(405)
    ctx.res:setBody("405 Method Not Allowed")
    return ctx.res
end

return HTTP405
