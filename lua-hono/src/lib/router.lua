---@alias HTTPMethod string
--
---@class Router
---@field trie Trie internal trie router
---@field add fun(self: Trie, method: HTTPMethod, path: string, ...: fun(...: any))
---@field match fun(self: Trie, method: HTTPMethod, path: string): TrieLeaf[], table<string, string>, boolean
--

local Trie = require("lib/trie-router/trie")

local Router = {}
Router.__index = Router
Router.__name = "TrieRouter"

function Router.new()
    return setmetatable({ trie = Trie.new() }, Router)
end

function Router:add(method, path, ...)
    self.trie:insert(method, (path or "*"), ...)
end

function Router:match(method, path)
    return self.trie:search(method, path)
end

return Router
