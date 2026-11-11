local variant = "moon"
local cache_path = vim.fn.stdpath "cache" .. "/rose-pine-" .. variant .. ".luac"

local function cache_key(dir)
    local stat = vim.uv.fs_stat(dir .. "/.git/index")
    return stat and (stat.mtime.sec .. "." .. stat.mtime.nsec) or nil
end

local function apply(theme)
    vim.o.background = theme.background
    vim.g.colors_name = theme.colors_name
    for _, hl in ipairs(theme.highlights) do
        vim.api.nvim_set_hl(0, hl[1], hl[2])
    end
    for i, color in pairs(theme.terminal_colors) do
        vim.g["terminal_color_" .. i] = color
    end
    local group = vim.api.nvim_create_augroup("rose-pine", {})
    for _, au in ipairs(theme.autocmds) do
        vim.api.nvim_create_autocmd(au.event, { group = group, pattern = au.pattern, command = au.command })
    end
end

-- rose-pine recomputes about 900 highlight groups on every startup,
-- so record its nvim_set_hl calls once and replay them from bytecode
local function load_and_record(key)
    local highlights = {}
    local set_hl = vim.api.nvim_set_hl
    vim.api.nvim_set_hl = function(ns, name, val)
        highlights[#highlights + 1] = { name, val }
        return set_hl(ns, name, val)
    end
    local ok, err = pcall(vim.cmd.colorscheme, "rose-pine-" .. variant)
    vim.api.nvim_set_hl = set_hl
    if not ok then
        error(err)
    end
    if not key then
        return
    end

    local terminal_colors = {}
    for i = 0, 15 do
        terminal_colors[i] = vim.g["terminal_color_" .. i]
    end
    local autocmds = {}
    for _, au in ipairs(vim.api.nvim_get_autocmds { group = "rose-pine" }) do
        autocmds[#autocmds + 1] = { event = au.event, pattern = au.pattern, command = au.command }
    end
    local theme = {
        key = key,
        background = vim.o.background,
        colors_name = vim.g.colors_name,
        highlights = highlights,
        terminal_colors = terminal_colors,
        autocmds = autocmds,
    }
    local chunk = loadstring("return " .. vim.inspect(theme))
    local file = chunk and io.open(cache_path, "wb")
    if file then
        -- selene: allow(incorrect_standard_library_use)
        file:write(string.dump(chunk, true))
        file:close()
    end
end

return {
    name = "rose-pine",
    "rose-pine/neovim",
    lazy = false,
    init = function(plugin)
        local key = cache_key(plugin.dir)
        local chunk = key and loadfile(cache_path)
        local ok, theme = pcall(chunk or error)
        if ok and type(theme) == "table" and theme.key == key then
            apply(theme)
        else
            load_and_record(key)
        end
    end,
}
