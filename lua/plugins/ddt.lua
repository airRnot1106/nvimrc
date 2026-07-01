return {
    name = "ddt",
    repo = "Shougo/ddt.vim",
    depends = { "ddt-ui-shell", "ddt-ui-terminal" },
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
    end,
}
