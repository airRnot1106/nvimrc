return {
    name = "nvim-aibo",
    repo = "lambdalisue/nvim-aibo",
    on_cmd = { "Aibo" },
    on_map = { n = { "<Leader>aq", "<Leader>ac", "<Leader>ar", "<Leader>ad" } },
    lua_source = function()
        require("aibo").setup()

        local function pum_relative(delta)
            return function()
                if vim.fn["pum#visible"]() then
                    vim.fn["pum#map#insert_relative"](delta)
                    return
                end
                if vim.fn.pumvisible() == 1 then
                    local key = vim.api.nvim_replace_termcodes(delta > 0 and "<C-n>" or "<C-p>", true, false, true)
                    vim.api.nvim_feedkeys(key, "n", false)
                    return
                end
                local plug = delta > 0 and "<Plug>(aibo-history-next)" or "<Plug>(aibo-history-prev)"
                vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(plug, true, false, true), "m", false)
            end
        end

        vim.api.nvim_create_autocmd("FileType", {
            pattern = "aibo-prompt*",
            callback = function(args)
                vim.fn["ddc#custom#patch_buffer"]("specialBufferCompletion", true)
                vim.keymap.set("i", "<C-p>", pum_relative(-1), { buffer = args.buf, silent = true })
                vim.keymap.set("i", "<C-n>", pum_relative(1), { buffer = args.buf, silent = true })
            end,
        })

        vim.keymap.set(
            "n",
            "<Leader>aq",
            '<Cmd>Aibo -opener="botright vsplit" claude<CR>',
            { noremap = true, silent = true }
        )
        vim.keymap.set(
            "n",
            "<Leader>ac",
            '<Cmd>Aibo -opener="botright vsplit" claude -c<CR>',
            { noremap = true, silent = true }
        )
        vim.keymap.set(
            "n",
            "<Leader>ar",
            '<Cmd>Aibo -opener="botright vsplit" claude -r<CR>',
            { noremap = true, silent = true }
        )
        vim.keymap.set("n", "<Leader>ad", "<Cmd>bdelete!<CR>", { noremap = true, silent = true })
    end,
}
