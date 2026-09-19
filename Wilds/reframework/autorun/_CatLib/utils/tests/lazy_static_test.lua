local LazyStatic = require("utils.lazy_static")

local g_call_count = 0
local g_lazy = LazyStatic.new(function()
    g_call_count = g_call_count + 1
    return "Hello, world!"
end)

assert(g_lazy.inner_value == nil)
assert(g_lazy.state == 0)
assert(g_lazy:value() == "Hello, world!")
assert(g_lazy:value() == "Hello, world!")
assert(g_lazy.inner_value == "Hello, world!")
assert(g_lazy.state == 1)
assert(g_call_count == 1)

print("OK")
