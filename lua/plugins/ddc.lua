return {
    {
        "Shougo/ddc.vim",
        dependencies = {
            "vim-denops/denops.vim",
            "Shougo/pum.vim",
            "Shougo/ddc-ui-pum",
            "Shougo/ddc-source-around",
            "matsui54/ddc-source-buffer",
            "Shougo/ddc-source-lsp",
            "LumaKernel/ddc-source-file",
            "gamoutatsumi/ddc-emoji",
            "Shougo/ddc-source-cmdline",
            "Shougo/ddc-source-cmdline-history",
            "tani/ddc-fuzzy",
            "matsui54/denops-popup-preview.vim",
            "L3MON4D3/LuaSnip",
        },
        event = { "BufReadPre", "BufNewFile" },
        config = function()
            local patch_global = vim.fn["ddc#custom#patch_global"]
            local patch_filetype = vim.fn["ddc#custom#patch_filetype"]
            patch_global("ui", "pum")

            patch_global("autoCompleteEvents", {
                "InsertEnter",
                "TextChangedI",
                "TextChangedP",
                "CmdlineChanged",
            })

            patch_global {
                sources = {
                    "around",
                    "buffer",
                    "lsp",
                    "file",
                    "emoji",
                    "cmdline",
                    "cmdline-history",
                },
                sourceOptions = {
                    _ = {
                        matchers = { "matcher_fuzzy" },
                        sorters = { "sorter_fuzzy" },
                        converters = { "converter_fuzzy" },
                        keywordPattern = [[[a-zA-Z_:]\w*]],
                    },
                    ["around"] = {
                        mark = "A",
                    },
                    ["buffer"] = {
                        mark = "B",
                    },
                    ["lsp"] = {
                        mark = "LSP",
                        dup = "keep",
                        keywordPattern = [[\k+]],
                        sorters = { "sorter_lsp-kind" },
                    },
                    ["file"] = {
                        mark = "F",
                        isVolatile = true,
                        forceCompletionPattern = [[\S/\S*]],
                    },
                    ["emoji"] = {
                        mark = "Emoji",
                        matchers = { "emoji" },
                        sorters = {},
                    },
                    ["cmdline"] = {
                        mark = "CMD",
                    },
                    ["cmdline-history"] = {
                        mark = "CMD-H",
                    },
                },
                sourceParams = {
                    ["around"] = {
                        maxSize = 500,
                    },
                    ["buffer"] = {
                        requireSameFiletype = false,
                        limitBytes = 5000000,
                        fromAltBuf = true,
                        forceCollect = true,
                    },
                    ["lsp"] = {
                        snippetEngine = vim.fn["denops#callback#register"](function(body)
                            require("luasnip").lsp_expand(body)
                        end),
                        enableResolveItem = true,
                        enableAdditionalTextEdit = true,
                    },
                },
            }

            patch_filetype({ "ps1", "dosbatch", "autohotkey", "registry" }, {
                sourceOptions = {
                    ["file"] = {
                        forceCompletionPattern = [[\S\\\S*]],
                    },
                },
                sourceParams = {
                    ["file"] = {
                        mode = "win32",
                    },
                },
            })

            patch_global("cmdlineSources", {
                [":"] = {
                    "cmdline",
                    "cmdline-history",
                    "around",
                },
                ["/"] = {
                    "around",
                },
                ["?"] = {
                    "around",
                },
            })

            vim.fn["ddc#enable"]()
            vim.fn["popup_preview#enable"]()
            vim.fn["ddc#enable_cmdline_completion"]()

            local pum_map_select_relative = vim.fn["pum#map#select_relative"]
            vim.api.nvim_create_autocmd("InsertEnter", {
                callback = function()
                    local ls = require "luasnip"

                    vim.keymap.set("i", "<Tab>", function()
                        return ls.expand_or_jumpable() and "<Plug>luasnip-expand-or-jump" or "<Tab>"
                    end, { silent = true, expr = true })

                    vim.keymap.set("i", "<S-Tab>", function()
                        ls.jump(-1)
                    end, { silent = true })

                    vim.keymap.set("s", "<Tab>", function()
                        ls.jump(1)
                    end, { silent = true })

                    vim.keymap.set("s", "<S-Tab>", function()
                        ls.jump(-1)
                    end, { silent = true })

                    vim.keymap.set("i", "<C-p>", function()
                        pum_map_select_relative(-1)
                    end, {})

                    vim.keymap.set("i", "<C-n>", function()
                        pum_map_select_relative(1)
                    end, {})

                    vim.keymap.set("i", "<C-y>", function()
                        return "<Cmd>call pum#map#confirm()<CR>"
                    end, { expr = true, silent = true, noremap = false })

                    vim.cmd [[
inoremap <silent><expr> <CR> pum#visible() ? pum#map#confirm() :
	\ "\<Cmd>call feedkeys(v:lua.require('nvim-autopairs').autopairs_cr(), 'in')\<CR>"
]]
                end,
            })

            vim.api.nvim_set_keymap("n", ":", "<Cmd>lua CommandlinePre()<CR>:", { noremap = true })
            vim.api.nvim_set_keymap("n", ";", "<Cmd>lua CommandlinePre()<CR>:", { noremap = true })

            function CommandlinePost()
                vim.api.nvim_del_keymap("c", "<Tab>")
                vim.api.nvim_del_keymap("c", "<S-Tab>")
                vim.api.nvim_del_keymap("c", "<C-n>")
                vim.api.nvim_del_keymap("c", "<C-p>")
                vim.api.nvim_del_keymap("c", "<C-y>")
                vim.api.nvim_del_keymap("c", "<C-e>")
            end

            function CommandlinePre()
                vim.api.nvim_set_keymap(
                    "c",
                    "<Tab>",
                    '<Cmd>lua vim.fn["pum#map#insert_relative"](1)<CR>',
                    { noremap = true }
                )
                vim.api.nvim_set_keymap(
                    "c",
                    "<S-Tab>",
                    '<Cmd>lua vim.fn["pum#map#insert_relative"](-1)<CR>',
                    { noremap = true }
                )
                vim.api.nvim_set_keymap(
                    "c",
                    "<C-n>",
                    '<Cmd>lua vim.fn["pum#map#insert_relative"](1)<CR>',
                    { noremap = true }
                )
                vim.api.nvim_set_keymap(
                    "c",
                    "<C-p>",
                    '<Cmd>lua vim.fn["pum#map#insert_relative"](-1)<CR>',
                    { noremap = true }
                )
                vim.api.nvim_set_keymap("c", "<C-y>", '<Cmd>lua vim.fn["pum#map#confirm"]()<CR>', { noremap = true })
                vim.api.nvim_set_keymap("c", "<C-e>", '<Cmd>lua vim.fn["pum#map#cancel"]()<CR>', { noremap = true })

                vim.api.nvim_create_autocmd("User", {
                    pattern = "DDCCmdlineLeave",
                    callback = function()
                        CommandlinePost()
                    end,
                    once = true,
                })

                vim.fn["ddc#enable_cmdline_completion"]()
            end
        end,
    },
}
