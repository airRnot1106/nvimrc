return {
    {
        "Shougo/ddu.vim",
        dependencies = {
            "vim-denops/denops.vim",
            "Shougo/cmdline.vim",
            "Shougo/ddu-ui-ff",
            "matsui54/ddu-source-file_external",
            "shun/ddu-source-rg",
            "yuki-yano/ddu-filter-fzf",
            "uga-rosa/ddu-filter-converter_devicon",
            "Shougo/ddu-kind-file",
        },
        event = { "BufReadPre", "BufNewFile" },
        config = function()
            vim.fn["ddu#custom#patch_global"] {
                ui = "ff",
                uiParams = {
                    ff = {
                        autoAction = {
                            name = "preview",
                        },
                        startAutoAction = true,
                        autoResize = false,
                        floatingBorder = "rounded",
                        previewFloating = true,
                        previewFloatingBorder = "rounded",
                        previewFloatingTitle = "Preview",
                        previewSplit = "vertical",
                        prompt = "> ",
                        split = "floating",
                    },
                },
                sourceOptions = {
                    _ = {
                        matchers = { "matcher_fzf" },
                        sorters = { "sorter_fzf" },
                        converters = { "converter_devicon" },
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
            }

            local resize = function()
                local columns = vim.opt.columns:get()
                local lines = vim.opt.lines:get()
                local width = math.floor(columns * 0.8)
                local filterWindow = {
                    col = math.floor(columns * 0.1),
                    row = lines / 2 - 13,
                    width = width,
                }
                local sourceWindow = {
                    col = math.floor(columns * 0.1),
                    row = lines / 2 - 10,
                    width = math.floor(width / 2.025),
                }
                local previewWindow = {
                    col = math.floor(columns * 0.51),
                    row = lines / 2 - 10,
                    width = math.floor(width / 2.025),
                    height = 20,
                }

                vim.fn["ddu#custom#patch_global"] {
                    uiParams = {
                        ff = {
                            winCol = sourceWindow.col,
                            winRow = sourceWindow.row,
                            winWidth = sourceWindow.width,
                            previewCol = previewWindow.col,
                            previewRow = previewWindow.row,
                            previewWidth = previewWindow.width,
                            previewHeight = 20,
                        },
                    },
                }
                vim.fn["cmdline#set_option"] {
                    border = "rounded",
                    highlight_prompt = "Statement",
                    highlight_window = "None",
                    row = filterWindow.row,
                    col = filterWindow.col,
                    width = filterWindow.width,
                }
            end

            vim.api.nvim_create_autocmd({ "VimResized" }, {
                pattern = { "*" },
                callback = resize,
            })
            resize()

            vim.fn["ddu#custom#patch_local"]("file", {
                sources = {
                    {
                        name = { "file_external" },
                    },
                },
                sourceParams = {
                    file_external = {
                        cmd = { vim.fn.expand "~/.nix-profile/bin/fd", ".", "-H", "-E", ".git", "-t", "f" },
                    },
                },
            })

            vim.fn["ddu#custom#patch_local"]("rg", {
                sources = {
                    {
                        name = { "rg" },
                        options = {
                            volatile = true,
                        },
                    },
                },
                sourceParams = {
                    rg = {
                        args = { "--json" },
                    },
                },
            })

            vim.api.nvim_create_autocmd("FileType", {
                pattern = "ddu-ff",
                callback = function()
                    vim.fn["ddu#ui#ff#save_cmaps"] { "<Esc>", "<CR>", "<C-n>", "<C-p>" }
                    local opts = { noremap = true, silent = true, buffer = true }
                    vim.keymap.set("c", "<Esc>", [[<Esc><Cmd>call ddu#ui#do_action('quit')<CR>]], opts)
                    vim.keymap.set("n", "q", [[<Esc><Cmd>call ddu#ui#do_action('quit')<CR>]], opts)
                    vim.keymap.set({ "n", "c" }, "<Cr>", [[<Cmd>call ddu#ui#do_action("itemAction")<CR><Esc>]], opts)
                    vim.keymap.set({ "n", "c" }, "<C-n>", function()
                        vim.fn["ddu#ui#do_action"]("cursorNext", {
                            loop = true,
                        })
                    end, opts)
                    vim.keymap.set({ "n", "c" }, "<C-p>", function()
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
                pattern = "Ddu:ui:ff:closeFilterWindow",
                callback = function()
                    vim.fn["ddu#ui#ff#restore_cmaps"]()
                end,
            })

            local dduStart = function(options)
                return function()
                    vim.fn["ddu#start"](options)
                end
            end

            local dduStartWithFilter = function(options)
                return function()
                    vim.fn["ddu#start"](options)

                    vim.api.nvim_create_autocmd("User", {
                        pattern = "Ddu:uiDone",
                        once = true,
                        nested = true,
                        callback = function()
                            vim.fn["ddu#ui#async_action"] "openFilterWindow"
                        end,
                    })

                    vim.api.nvim_create_autocmd("User", {
                        pattern = "Ddu:ui:ff:openFilterWindow",
                        once = true,
                        nested = true,
                        callback = function()
                            vim.fn["cmdline#enable"]()
                        end,
                    })
                end
            end

            local opts = { noremap = true, silent = true }
            vim.keymap.set("n", "<Leader>tf", dduStartWithFilter { name = "file" }, opts)
            vim.keymap.set("n", "<Leader>tr", dduStartWithFilter { name = "rg" }, opts)
        end,
    },
}
