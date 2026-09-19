--- A simple try-catch like construct for Lua.
---@author: Eigeen
---@date: 2024/12/06

-- Usage:
--
-- try {
--     function()
--         print("Hello, world!")
--     end,
--     catch = function(err)
--         print("Caught error: ".. err)
--     end,
--     finally = function()
--         print("Finally block")
--     end
-- }

local function try(block)
    -- local try_fn = block[1]
    local try_fn = block[1]
    assert(type(try_fn) == "function", "try block must start with a function")

    local catch_fn = block[2] or block['catch']
    if catch_fn then
        assert(type(catch_fn) == "function", "catch block must be a function")
    end

    local finally_fn = block[3] or block['finally']
    if finally_fn then
        assert(type(finally_fn) == "function", "finally block must be a function")
    end

    local ok, err = pcall(try_fn)
    if not ok then
        if catch_fn then
            catch_fn(err)
        else
            error(err)
        end
    end

    if finally_fn then
        finally_fn()
    end
end

return try
