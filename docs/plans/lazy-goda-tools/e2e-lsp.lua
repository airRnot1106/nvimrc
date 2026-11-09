local out = {}
vim.cmd.edit(os.getenv "E2E_FILE")
vim.bo.filetype = "lua"
vim.api.nvim_buf_set_lines(0, 0, -1, false, { "local x = 1", "" })
vim.api.nvim_win_set_cursor(0, { 2, 0 })
vim.defer_fn(function()
    vim.api.nvim_input "i"
end, 3000)
for i, ch in ipairs { "s", "t", "r", "i", "n", "g", ".", "u", "p" } do
    vim.defer_fn(function()
        vim.api.nvim_input(ch)
    end, 9000 + i * 400)
end
local n, t = 0, vim.uv.new_timer()
t:start(
    14000,
    500,
    vim.schedule_wrap(function()
        n = n + 1
        local ok, vis = pcall(vim.fn["pum#visible"])
        if (ok and vis) or n > 16 then
            t:stop()
            local items = {}
            pcall(function()
                for _, it in ipairs(vim.fn["pum#_get"]().items or {}) do
                    items[#items + 1] = it.word .. "<" .. (it.menu or "") .. ">"
                end
            end)
            local lc = #vim.lsp.get_clients()
            out[#out + 1] = string.format(
                "pum=%s n=%d line=%q nvim_lsp_clients=%d items=%s",
                tostring(vis),
                n,
                vim.fn.getline ".",
                lc,
                table.concat(items, ",")
            )
            local _, lg = pcall(vim.fn.execute, "echo goda#log()")
            out[#out + 1] = tostring(lg):gsub("\n", " "):sub(1, 300)
            out[#out + 1] = "lua_ls_procs=" .. vim.trim(vim.fn.system "pgrep -f lua-language-server | wc -l")
            vim.fn.writefile(out, os.getenv "E2E_OUT")
            vim.cmd "qa!"
        end
    end)
)
