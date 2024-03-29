---@type nu
local gui = require("yue.gui")

local Version = require("Package/Version")
local Lua = require("Package/Lua")

local pkg = Lua:create()

---@type Package.Version?
local selected_lua_version = nil
local lua_is_jit = false

---@type luvit.http.ClientRequest[]
local reqs

local function ui()
    local lua_container = gui.Container.create()

    local lua_header = gui.Label.create("Select Lua version")
    -- lua_header:setfont(common.fonts.subheader)
    lua_container:addchildview(lua_header)

    local fetching_text = gui.Label.create("Fetching versions...")
    lua_container:addchildview(fetching_text)

    local fetching_pgbar = gui.ProgressBar.create()
    lua_container:addchildview(fetching_pgbar)

    local picker = gui.Picker.create()
    picker:setstyle {
        height = 25,
        ["margin-top"] = 10,
    }
    reqs = pkg:fetch_versions(nil,
        function(version, checked, total)
            local percent = checked / total * 100
            fetching_text:settext(string.format("Fetching versions... %d/%d (%.2f%%)", checked, total, percent))
            fetching_pgbar:setvalue(percent)
            if percent >= 100 then
                fetching_text:setvisible(false);
                fetching_pgbar:setvisible(false);
            end

            picker:additem(tostring(version))

            ---@type Package.Version[]
            local vers = {}

            for i, v in ipairs(picker:getitems() --[[@as string[] ]]) do
                if v == "None" or v:find("LuaJIT") then goto next end

                --replace all %d with (%d+) to capture the version numbers
                vers[#vers+1] = Version:from_string(v)
                ::next::
            end

            table.sort(vers, function(a, b) return a > b end)

            picker:clear()

            picker:additem("LuaJIT v2.1.0")

            for _, v in ipairs(vers) do
                picker:additem(tostring(v))
            end

            picker:additem("None")

            --Make the latest PUC Lua version the default
            picker:selectitemat(2)
        end
    )

    function picker:onselectionchange()
        local sel = picker:getselecteditem()
        if sel == "None" then selected_lua_version = nil; return; end

        if sel:find("LuaJIT") then
            --LuaJIT
            selected_lua_version = Version:create(2, 1, 0)
            lua_is_jit = true
        else
            selected_lua_version = Version:from_string(sel)
            lua_is_jit = false
        end

        print("Selected Lua version: "..(lua_is_jit and "LuaJIT " or "Lua ")..tostring(selected_lua_version))
    end

    lua_container:addchildview(picker)

    return lua_container
end

---@param progress nu.ProgressBar
local function download(to, progress)
    if not selected_lua_version then return end
end

---@param to string
local function install(to)
    if not selected_lua_version then return end
end

local function cleanup()
    for _, req in ipairs(reqs) do req:destroy() end
end

---@type Page
return {
    name = "Lua",
    ui = ui,
    on_download = download,
    on_install = install,
    on_cleanup = cleanup,
}
