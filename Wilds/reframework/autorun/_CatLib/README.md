# _CatLib 常用函数

引入 _CatLib：

```lua
local Core = require("_CatLib")
```

## Mod 基本结构

### 创建新的 mod

```lua
local mod = Core.NewMod("Mod Name")
```

会自动根据传入的 mod name 创建对应的配置文件。

配置项存储在 `mod.Config` 对象中，自带 `Enable` 和 `Debug` 两个 bool 值。

### mod 配置

使用 `mod.Menu` 来创建 mod 菜单。传入的函数返回值为 true 表示配置变更，需要保存配置。

```lua
if mod.Config.SomeOption == nil then
    mod.Config.SomeOption = true
end

mod.Menu(function ()
    local configChanged = false
    local changed = false

    changed, mod.Config.SomeOption = imgui.checkbox("SomeOption", mod.Config.SomeOption)
    configChanged = configChanged or changed
    if changed then
        -- apply sth
    end

    return configChanged
end)
```

### mod 工具函数

下面的函数都自动包含了 `mod.Config.Enable` 检查，当该项为 false 时全部不执行。

```lua
-- 可以省略 post hook
mod.HookFunc("XXXType", "XXXMethod",
function (args)
end)

mod.HookFunc("XXXType", "XXXMethod",
function (args)
end, function (retval)
    return retval
end)

mod.OnUpdateBehavior(function ()
end)

mod.OnFrame(function ()
end)

-- 同时检测 mod.Config.Debug
mod.OnDebugFrame(function ()
    -- DisplaySomeDebugInfo()
end)

mod.D2dRegister(function ()
end)

mod.Run()
```

## Core 工具函数

