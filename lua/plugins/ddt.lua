return {
    name = "ddt",
    repo = "Shougo/ddt.vim",
    depends = { "ddt-ui-shell", "ddt-ui-terminal", "nui" },
    on_event = { "VimEnter" },
    lua_source = function()
        local ddt_cache_dir = vim.fn.stdpath "cache" .. "/ddt"
        vim.fn.mkdir(ddt_cache_dir, "p")

        local patch_global = vim.fn["ddt#custom#patch_global"]

        patch_global("uiParams", {
            shell = {
                noSaveHistoryCommands = { "exit" },
                shellHistoryPath = ddt_cache_dir .. "/ddt-shell-history",
                prompt = "$",
                promptPattern = "\\$ ",
            },
            terminal = {
                -- the nvim flake wrapper exports XDG_CONFIG_HOME pointing at the
                -- read-only flake source; unset it so the spawned shell loads the
                -- user's real ~/.config (sheldon etc.)
                command = { "/bin/sh", "-c", "unset XDG_CONFIG_HOME; exec zsh" },
                promptPattern = "\\w\\+@[0-9A-Za-z._-]\\+ ",
            },
        })

        local ddt_shell_group = vim.api.nvim_create_augroup("ddt-shell", {
            clear = true,
        })
        vim.api.nvim_create_autocmd("FileType", {
            group = ddt_shell_group,
            pattern = "ddt-shell",
            callback = function(args)
                local opts = { buffer = args.buf, silent = true }

                vim.keymap.set({ "n", "i" }, "<CR>", function()
                    vim.fn["ddt#ui#do_action"] "executeLine"
                end, opts)
                vim.keymap.set({ "n", "i" }, "<C-n>", function()
                    vim.fn["ddt#ui#do_action"] "nextPrompt"
                end, opts)
                vim.keymap.set({ "n", "i" }, "<C-p>", function()
                    vim.fn["ddt#ui#do_action"] "previousPrompt"
                end, opts)
                vim.keymap.set({ "n", "i" }, "<C-c>", function()
                    vim.fn["ddt#ui#do_action"] "terminate"
                end, opts)
                vim.keymap.set({ "n", "i" }, "<C-l>", function()
                    vim.fn["ddt#ui#do_action"] "redraw"
                end, opts)
            end,
        })

        local ddt_terminal_group = vim.api.nvim_create_augroup("ddt-terminal", {
            clear = true,
        })
        vim.api.nvim_create_autocmd("FileType", {
            group = ddt_terminal_group,
            pattern = "ddt-terminal",
            callback = function(args)
                local opts = { buffer = args.buf, silent = true }

                vim.keymap.set({ "n" }, "<C-n>", function()
                    vim.fn["ddt#ui#do_action"] "nextPrompt"
                end, opts)
                vim.keymap.set({ "n" }, "<C-p>", function()
                    vim.fn["ddt#ui#do_action"] "previousPrompt"
                end, opts)
                vim.keymap.set({ "n" }, "<C-l>", function()
                    vim.fn["ddt#ui#do_action"] "redraw"
                end, opts)
            end,
        })

        vim.keymap.set("n", "<C-s><C-s>", function()
            vim.fn["ddt#start"] {
                name = vim.t.ddt_ui_shell_last_name or ("shell-" .. vim.fn.win_getid()),
                ui = "shell",
            }
        end)
        vim.keymap.set("n", "<C-s><C-t>", function()
            vim.fn["ddt#start"] {
                name = vim.t.ddt_ui_terminal_last_name or ("terminal-" .. vim.fn.win_getid()),
                ui = "terminal",
            }
        end)

        local float_popup

        local function find_float_terminal_buf()
            for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                if vim.api.nvim_buf_is_loaded(buf) and vim.b[buf].ddt_ui_name == "floating-terminal" then
                    return buf
                end
            end
        end

        -- close the border window together when the popup is closed with :q
        -- etc.; hide() keeps the terminal buffer alive unlike unmount()
        local function hide_on_win_closed(popup)
            vim.api.nvim_create_autocmd("WinClosed", {
                pattern = tostring(popup.winid),
                once = true,
                callback = function()
                    popup:hide()
                end,
            })
        end

        -- recalculate the "%" based size and position on editor resize;
        -- while hidden this only refreshes win_config for the next show()
        vim.api.nvim_create_autocmd("VimResized", {
            callback = function()
                if float_popup then
                    float_popup:update_layout()
                end
            end,
        })

        vim.keymap.set({ "n", "t" }, "<F7>", function()
            if float_popup and float_popup.winid and vim.api.nvim_win_is_valid(float_popup.winid) then
                float_popup:hide()
                return
            end

            local terminal_buf = find_float_terminal_buf()

            if float_popup and terminal_buf then
                -- reuse the existing session: just re-show the window.
                -- do NOT call ddt#start here, or it will respawn the shell
                -- (and reset its cwd to the project root) on every toggle
                float_popup.bufnr = terminal_buf
                float_popup:show()
                hide_on_win_closed(float_popup)
                vim.schedule(function()
                    vim.cmd "startinsert"
                end)
            else
                local Popup = require "nui.popup"
                float_popup = Popup {
                    enter = true,
                    focusable = true,
                    relative = "editor",
                    position = "50%",
                    size = { width = "80%", height = "80%" },
                    border = {
                        style = "rounded",
                        text = { top = " terminal ", top_align = "center" },
                    },
                    -- reuse the existing session if the popup object was lost;
                    -- an explicit bufnr is never deleted by nui
                    bufnr = terminal_buf,
                }
                float_popup:mount()
                hide_on_win_closed(float_popup)

                -- only start a fresh shell when there is no existing one
                vim.fn["ddt#start"] {
                    name = "floating-terminal",
                    ui = "terminal",
                }

                vim.schedule(function()
                    vim.cmd "startinsert"
                end)
            end
        end)
    end,
}
