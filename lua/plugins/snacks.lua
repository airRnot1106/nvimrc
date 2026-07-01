return {
    name = "snacks",
    repo = "folke/snacks.nvim",
    on_event = { "VimEnter" },
    lua_source = function()
        -- reuse the current window for lazygit-edited files, but open a new tab
        -- while only the startup screen is shown
        -- selene: allow(global_usage)
        function _G.SnacksLazygitNewTab()
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
            local dashboards = {
                snacks_dashboard = true,
                alpha = true,
                dashboard = true,
                starter = true,
                ministarter = true,
            }
            if dashboards[bo.filetype] then
                return 1
            end
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

        -- inside nvim, quit lazygit first then route to --remote or --remote-tab
        local lazygit_edit =
            '[ -z "$NVIM" ] && (nvim -- {{filename}}) || (nvim --server "$NVIM" --remote-send "q" && (test "$(nvim --server "$NVIM" --remote-expr "v:lua.SnacksLazygitNewTab()")" = 1 && nvim --server "$NVIM" --remote-tab {{filename}} || nvim --server "$NVIM" --remote {{filename}}))'
        local lazygit_edit_at_line =
            '[ -z "$NVIM" ] && (nvim +{{line}} -- {{filename}}) || (nvim --server "$NVIM" --remote-send "q" && (test "$(nvim --server "$NVIM" --remote-expr "v:lua.SnacksLazygitNewTab()")" = 1 && (nvim --server "$NVIM" --remote-tab {{filename}} && nvim --server "$NVIM" --remote-send ":{{line}}<CR>") || (nvim --server "$NVIM" --remote {{filename}} && nvim --server "$NVIM" --remote-send ":{{line}}<CR>")))'
        local lazygit_open_dir =
            '[ -z "$NVIM" ] && (nvim -- {{dir}}) || (nvim --server "$NVIM" --remote-send "q" && (test "$(nvim --server "$NVIM" --remote-expr "v:lua.SnacksLazygitNewTab()")" = 1 && nvim --server "$NVIM" --remote-tab {{dir}} || nvim --server "$NVIM" --remote {{dir}}))'

        local snacks = require "snacks"
        snacks.setup {
            input = { enabled = true },
            lazygit = {
                enabled = true,
                config = {
                    os = {
                        editPreset = "nvim-remote",
                        edit = lazygit_edit,
                        editAtLine = lazygit_edit_at_line,
                        openDirInEditor = lazygit_open_dir,
                    },
                },
            },
            picker = { enabled = true },
        }
        vim.ui.input = snacks.input.input
        vim.ui.select = snacks.picker.select

        vim.keymap.set("n", "<Leader>lg", function()
            snacks.lazygit.open()
        end, { desc = "Open lazygit" })
    end,
}
