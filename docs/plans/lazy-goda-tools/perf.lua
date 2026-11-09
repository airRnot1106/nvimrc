local t0 = vim.uv.hrtime()
local function ms()
    return (vim.uv.hrtime() - t0) / 1e6
end
local out = {}
vim.api.nvim_create_autocmd("VimEnter", {
    once = true,
    callback = function()
        out.vimenter = ms()
        vim.schedule(function()
            vim.cmd.edit(os.getenv "PERF_FILE")
            vim.bo.filetype = "lua"
            vim.api.nvim_buf_set_lines(0, 0, -1, false, { "local alphabetical = 1", "local alphanumeric = 2", "" })
            vim.api.nvim_win_set_cursor(0, { 3, 0 })
            local t = vim.uv.new_timer()
            local start
            t:start(
                0,
                2,
                vim.schedule_wrap(function()
                    if
                        not out.ui
                        and package.loaded["telescope"]
                        and package.loaded["noice"]
                        and package.loaded["barbar"]
                    then
                        out.ui = ms()
                        vim.defer_fn(function()
                            vim.api.nvim_input "i"
                            vim.defer_fn(function()
                                start = ms()
                                vim.api.nvim_input "alph"
                            end, 1500)
                        end, 100)
                    end
                    if start then
                        local ok, vis = pcall(vim.fn["pum#visible"])
                        if (ok and vis) or ms() - start > 8000 then
                            t:stop()
                            out.pum = ms() - start
                            out.ok = ok and vis
                            vim.fn.writefile({ vim.json.encode(out) }, os.getenv "PERF_OUT")
                            vim.cmd "qa!"
                        end
                    end
                end)
            )
        end)
    end,
})
