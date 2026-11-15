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

        local group = vim.api.nvim_create_augroup("kanaemi", {})
        local function set_abc()
            pcall(vim.fn["kanaemi#set_mode"], "abc")
        end

        vim.api.nvim_create_autocmd("InsertLeave", {
            group = group,
            pattern = "*",
            callback = set_abc,
            desc = "Switch Kanaemi back to ABC mode when leaving insert mode",
        })
        vim.api.nvim_create_autocmd("CmdlineLeave", {
            group = group,
            pattern = { "/", "?" },
            callback = set_abc,
            desc = "Switch Kanaemi back to ABC mode when leaving search",
        })
    end,
}
