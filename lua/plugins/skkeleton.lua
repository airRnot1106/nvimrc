return {
    {
        "vim-skk/skkeleton",
        dependencies = {
            { "vim-denops/denops.vim" },
            { "delphinus/skkeleton_indicator.nvim" },
        },
        event = "InsertEnter",
        init = function()
            vim.api.nvim_create_autocmd("User", {
                pattern = "skkeleton-initialize-pre",
                callback = function()
                    vim.fn["skkeleton#config"] {
                        globalDictionaries = {
                            vim.fn.expand "~/.config/skk/SKK-JISYO.L",
                        },
                        eggLikeNewline = true,
                        keepState = true,
                    }
                    vim.fn["skkeleton#register_kanatable"]("rom", {
                        ["jj"] = "escape",
                    })
                end,
                group = vim.api.nvim_create_augroup("skkelectonInitPre", { clear = true }),
            })
        end,
        config = function()
            vim.keymap.set("i", "<C-j>", "<Plug>(skkeleton-enable)", { noremap = false })
            vim.keymap.set("c", "<C-j>", "<Plug>(skkeleton-enable)", { noremap = false })
            require("skkeleton_indicator").setup {
                border = "rounded",
                eijiHlName = "LineNr",
                hiraHlName = "String",
                kataHlName = "Todo",
                hankataHlName = "Special",
                zenkakuHlName = "LineNr",
            }
        end,
    },
}
