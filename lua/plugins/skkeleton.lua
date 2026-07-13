return {
    name = "skkeleton",
    repo = "vim-skk/skkeleton",
    depends = { "skkeleton_indicator" },
    lazy = false,
    lua_add = function()
        vim.g["denops#server#deno_args"] = { "-q", "--no-lock", "--unstable-kv", "-A" }
        vim.api.nvim_create_autocmd("User", {
            pattern = "skkeleton-initialize-pre",
            callback = function()
                local skkeleton_data_dir = vim.fn.stdpath "data" .. "/skkeleton"
                vim.fn.mkdir(skkeleton_data_dir, "p")
                vim.fn["skkeleton#config"] {
                    globalDictionaries = {
                        vim.fn.expand "~/.config/skk/SKK-JISYO.L",
                    },
                    eggLikeNewline = true,
                    keepState = true,
                    registerConvertResult = true,
                    sources = { "deno_kv", "google_japanese_input" },
                    databasePath = skkeleton_data_dir .. "/skkeleton.db",
                    completionRankFile = skkeleton_data_dir .. "/rank.json",
                }
                vim.fn["skkeleton#register_kanatable"]("rom", {
                    ["jj"] = "escape",
                })
            end,
            group = vim.api.nvim_create_augroup("skkeletonInitPre", { clear = true }),
        })
        vim.keymap.set(
            { "i", "c" },
            "<C-j>",
            "<Plug>(skkeleton-enable)",
            { noremap = false, desc = "Enable skkeleton" }
        )
        vim.keymap.set(
            { "i", "c" },
            "<C-l>",
            "<Plug>(skkeleton-disable)",
            { noremap = false, desc = "Disable skkeleton" }
        )

        -- skkeleton#internal#map#restore() clears all buffer-local insert
        -- keymaps via `mapclear <buffer>` before restoring a pre-enable
        -- snapshot, which can permanently wipe nvim-autopairs' keymaps if
        -- they were attached after that snapshot was taken. Force
        -- nvim-autopairs to re-attach every time skkeleton is disabled.
        vim.api.nvim_create_autocmd("User", {
            pattern = "skkeleton-disable-post",
            callback = function()
                local ok, autopairs = pcall(require, "nvim-autopairs")
                if ok then
                    autopairs.force_attach()
                end
            end,
        })
    end,
}
