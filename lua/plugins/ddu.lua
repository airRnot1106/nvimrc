return {
    {
        "Shougo/ddu.vim",
        dependencies = {
            "vim-denops/denops.vim",
            "Shougo/cmdline.vim",
            "Shougo/ddu-ui-ff",
            "matsui54/ddu-source-file_external",
            "yuki-yano/ddu-filter-fzf",
            "uga-rosa/ddu-filter-converter_devicon",
            "Shougo/ddu-kind-file",
        },
        event = { "BufReadPre", "BufNewFile" },
        config = function()
            local lines = vim.opt.lines:get()
            local columns = vim.opt.columns:get()
            local width = math.floor(columns * 0.8)
            local filterWindow = {
                width = width,
                row = lines / 2 - 13,
                col = math.floor(columns * 0.1),
            }
            local sourceWindow = {
                width = math.floor(width / 2.025),
                row = lines / 2 - 10,
                col = math.floor(columns * 0.1),
            }
            local previewWindow = {
                width = math.floor(width / 2.025),
                height = 20,
                row = lines / 2 - 10,
                col = math.floor(columns * 0.51),
            }

            vim.fn["ddu#custom#patch_global"] {
                ui = "ff",
                sources = {
                    {
                        name = "file_external",
                    },
                },
                sourceOptions = {
                    _ = {
                        matchers = { "matcher_fzf" },
                        sorters = { "sorter_fzf" },
                        converters = { "converter_devicon" },
                    },
                },
                sourceParams = {
                    file_external = {
                        cmd = { vim.fn.expand "~/.nix-profile/bin/fd", ".", "-H", "-E", ".git", "-t", "f" },
                    },
                },
                filterParams = {
                    matcher_fzf = {
                        highlightMatched = "Search",
                    },
                },
                kindOptions = {
                    file = {
                        defaultAction = "open",
                    },
                },
                uiParams = {
                    ff = {
                        autoAction = {
                            name = "preview",
                        },
                        startAutoAction = true,
                        autoResize = true,
                        floatingBorder = "rounded",
                        prompt = "> ",
                        split = "floating",
                        winRow = sourceWindow.row,
                        winCol = sourceWindow.col,
                        winWidth = sourceWindow.width,
                        previewFloating = true,
                        previewSplit = "vertical",
                        previewFloatingBorder = "rounded",
                        previewRow = previewWindow.row,
                        previewCol = previewWindow.col,
                        previewWidth = previewWindow.width,
                        previewHeight = previewWindow.height,
                    },
                },
            }

            vim.api.nvim_create_autocmd("User", {
                pattern = "Ddu:ui:ff:closeFilterWindow",
                callback = function()
                    vim.fn["ddu#ui#ff#restore_cmaps"]()
                end,
            })

            vim.api.nvim_create_autocmd("FileType", {
                pattern = "ddu-ff",
                callback = function()
                    vim.fn["ddu#ui#ff#save_cmaps"] { "<Esc>", "<CR>", "<C-n>", "<C-p>" }
                    local opts = { noremap = true, silent = true, buffer = true }
                    vim.keymap.set("c", "<Esc>", [[<Esc><Cmd>call ddu#ui#do_action('quit')<CR>]], opts)
                    vim.keymap.set("c", "<Cr>", [[<Cmd>call ddu#ui#do_action("itemAction")<CR><Esc>]], opts)
                    vim.keymap.set("c", "<C-n>", function()
                        vim.fn["ddu#ui#do_action"]("cursorNext", {
                            loop = true,
                        })
                    end, opts)
                    vim.keymap.set("c", "<C-p>", function()
                        vim.fn["ddu#ui#do_action"]("cursorPrevious", {
                            loop = true,
                        })
                    end, opts)
                    vim.keymap.set("n", "i", function()
                        vim.fn["ddu#ui#do_action"] "openFilterWindow"
                    end, opts)
                end,
            })

            vim.api.nvim_create_autocmd("User", {
                pattern = "Ddu:uiDone",
                nested = true,
                callback = function()
                    vim.fn["ddu#ui#async_action"] "openFilterWindow"
                end,
            })

            vim.api.nvim_create_autocmd("User", {
                pattern = "Ddu:ui:ff:openFilterWindow",
                callback = function()
                    vim.fn["cmdline#set_option"] {
                        border = "rounded",
                        highlight_prompt = "Statement",
                        highlight_window = "None",
                        row = filterWindow.row,
                        col = filterWindow.col,
                        width = filterWindow.width,
                    }
                    vim.fn["cmdline#enable"]()
                end,
            })
        end,
    },
}
