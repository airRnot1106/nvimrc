local out = {}
vim.cmd.edit(os.getenv "E2E_FILE")
vim.bo.filetype = "lua"
vim.api.nvim_buf_set_lines(0, 0, -1, false, { "local x = 1", "" })
vim.api.nvim_win_set_cursor(0, { 2, 0 })
local mode = os.getenv "E2E_MODE"
local function fin()
    out[#out + 1] = "log=" .. tostring(vim.fn.execute "echo goda#log()"):gsub("\n", " "):sub(1, 240)
    vim.fn.writefile(out, os.getenv "E2E_OUT")
    vim.cmd "qa!"
end
vim.defer_fn(function()
    vim.api.nvim_input "i"
    vim.defer_fn(function()
        local t0 = vim.uv.hrtime()
        vim.api.nvim_input(mode == "snippet" and "fun" or "string.up")
        local n, t = 0, vim.uv.new_timer()
        t:start(
            0,
            2,
            vim.schedule_wrap(function()
                n = n + 1
                local ok, vis = pcall(vim.fn["pum#visible"])
                if (ok and vis) or n > 1500 then
                    t:stop()
                    local ms = (vim.uv.hrtime() - t0) / 1e6
                    local items = {}
                    pcall(function()
                        for _, it in ipairs(vim.fn["pum#_get"]().items or {}) do
                            items[#items + 1] = it.abbr or it.word
                        end
                    end)
                    local procs = vim.trim(vim.fn.system "ps -axo command | grep -c '[l]ua-language-server'")
                    out[#out + 1] = string.format(
                        "ms=%.0f vis=%s procs=%s items=%s",
                        ms,
                        tostring(vis),
                        procs,
                        table.concat(items, "|"):sub(1, 90)
                    )
                    if mode ~= "snippet" then
                        return fin()
                    end
                    local idx
                    for i, w in ipairs(items) do
                        if w:find "%(%)" or w:find "function %(" then
                            idx = i
                            break
                        end
                    end
                    out[#out + 1] = "snippet_index=" .. tostring(idx)
                    vim.api.nvim_input(string.format("<Cmd>call pum#map#insert_relative(%d)<CR>", idx or 1))
                    vim.defer_fn(function()
                        vim.api.nvim_input "<Cmd>call pum#map#confirm()<CR>"
                        vim.defer_fn(function()
                            out[#out + 1] = "lines="
                                .. vim.inspect(vim.api.nvim_buf_get_lines(0, 1, -1, false)):gsub("\n", " ")
                                .. " snippet_active="
                                .. tostring(vim.snippet.active())
                            fin()
                        end, 800)
                    end, 300)
                end
            end)
        )
    end, 500)
end, tonumber(os.getenv "E2E_WAIT" or "7000"))
