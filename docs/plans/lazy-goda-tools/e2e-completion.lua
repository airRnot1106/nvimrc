local out = {}
vim.cmd.edit(os.getenv "E2E_FILE")
vim.bo.filetype = "lua"
vim.api.nvim_buf_set_lines(0, 0, -1, false, { "local alphabetical = 1", "local alphanumeric = 2", "" })
vim.api.nvim_win_set_cursor(0, { 3, 0 })
local function keys(k)
    vim.api.nvim_input(k)
end
vim.defer_fn(function()
    keys "i"
end, 1500)
for i, ch in ipairs { "a", "l", "p", "h" } do
    vim.defer_fn(function()
        keys(ch)
    end, 3000 + i * 400)
end
local n = 0
local t = vim.uv.new_timer()
t:start(
    5500,
    500,
    vim.schedule_wrap(function()
        n = n + 1
        local ok, vis = pcall(vim.fn["pum#visible"])
        local native = vim.fn.pumvisible()
        if (ok and vis) or native == 1 or n > 30 then
            t:stop()
            local items = {}
            pcall(function()
                for _, it in ipairs(vim.fn["pum#_get"]().items or {}) do
                    items[#items + 1] = it.word
                end
            end)
            out[#out + 1] = string.format(
                "pum=%s native=%d n=%d mode=%s line=%q items=%s",
                tostring(vis),
                native,
                n,
                vim.fn.mode(),
                vim.fn.getline ".",
                table.concat(items, ",")
            )
            vim.fn.writefile(out, os.getenv "E2E_OUT")
            vim.cmd "qa!"
        end
    end)
)
