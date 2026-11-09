return {
    name = "kanaemi.vim",
    "kanaemi-app/kanaemi.vim",
    event = { "VimEnter" },
    init = function()
        vim.g.kanaemi_port = 50123
    end,
    config = function()
        vim.g.kanaemi_mode = "abc"
        pcall(function()
            vim.g.kanaemi_mode = vim.fn["kanaemi#get_mode"]()
        end)
        pcall(vim.fn["kanaemi#watch_mode"], function(mode)
            vim.g.kanaemi_mode = mode
            vim.cmd.redrawstatus()
        end)

        vim.api.nvim_create_autocmd("InsertLeave", {
            group = vim.api.nvim_create_augroup("kanaemi", {}),
            pattern = "*",
            callback = function()
                pcall(vim.fn["kanaemi#set_mode"], "abc")
            end,
            desc = "Switch Kanaemi back to ABC mode when leaving insert mode",
        })
    end,
}
