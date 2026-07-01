return {
    name = "lazygit",
    repo = "kdheepak/lazygit.nvim",
    on_cmd = { "LazyGit", "LazyGitCurrentFile", "LazyGitConfig" },
    on_map = { n = { "<Leader>lg" } },
    lua_source = function()
        -- load the repo-managed config (theme + nvim-remote edit integration)
        vim.g.lazygit_use_custom_config_file_path = 1
        vim.g.lazygit_config_file_path = vim.fn.stdpath "config" .. "/lazygit/config.yaml"
        -- nvr is not installed; rely on lazygit os.edit + editPreset instead
        vim.g.lazygit_use_neovim_remote = 0

        -- reuse the current window for lazygit-edited files, but open a new tab
        -- while only the startup screen is shown
        -- global is required so lazygit can call it via v:lua.LazygitNewTab()
        -- selene: allow(global_usage)
        function _G.LazygitNewTab()
            local win = vim.api.nvim_get_current_win()
            if vim.api.nvim_win_get_config(win).relative ~= "" then
                for _, w in ipairs(vim.api.nvim_list_wins()) do
                    if vim.api.nvim_win_get_config(w).relative == "" then
                        win = w
                        break
                    end
                end
            end
            local buf = vim.api.nvim_win_get_buf(win)
            local bo = vim.bo[buf]
            if bo.buftype ~= "" then
                return 1
            end
            if vim.api.nvim_buf_get_name(buf) == "" then
                local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
                if #lines == 0 or (#lines == 1 and lines[1] == "") then
                    return 1
                end
            end
            return 0
        end

        vim.keymap.set("n", "<Leader>lg", "<Cmd>LazyGit<CR>", { desc = "Open lazygit" })
    end,
}
