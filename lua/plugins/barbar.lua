return {
    name = "barbar",
    repo = "romgrk/barbar.nvim",
    depends = { "nvim-web-devicons" },
    on_event = { "VimEnter" },
    lua_add = function()
        -- disable auto setup so the options in lua_source take effect
        vim.g.barbar_auto_setup = false
    end,
    lua_source = function()
        require("barbar").setup {
            animation = true,
            -- mouse is disabled in this config, so drop click handlers
            clickable = false,
            icons = {
                diagnostics = {
                    [vim.diagnostic.severity.ERROR] = { enabled = true },
                    [vim.diagnostic.severity.WARN] = { enabled = true },
                },
            },
        }

        local map = vim.keymap.set
        -- navigation
        map("n", "[b", "<Cmd>BufferPrevious<CR>", { silent = true, desc = "Previous buffer" })
        map("n", "]b", "<Cmd>BufferNext<CR>", { silent = true, desc = "Next buffer" })
        map("n", "<Leader>[", "<Cmd>BufferPrevious<CR>", { silent = true, desc = "Previous buffer" })
        map("n", "<Leader>]", "<Cmd>BufferNext<CR>", { silent = true, desc = "Next buffer" })
        -- reorder
        map("n", "[B", "<Cmd>BufferMovePrevious<CR>", { silent = true, desc = "Move buffer left" })
        map("n", "]B", "<Cmd>BufferMoveNext<CR>", { silent = true, desc = "Move buffer right" })
        -- goto by index
        for i = 1, 9 do
            map("n", "<Leader>" .. i, "<Cmd>BufferGoto " .. i .. "<CR>", { silent = true, desc = "Go to buffer " .. i })
        end
        map("n", "<Leader>0", "<Cmd>BufferLast<CR>", { silent = true, desc = "Go to last buffer" })
        -- operations
        map("n", "<Leader>bp", "<Cmd>BufferPin<CR>", { silent = true, desc = "Pin buffer" })
        map("n", "<Leader>bc", "<Cmd>BufferClose<CR>", { silent = true, desc = "Close buffer" })
        map("n", "<Leader>d", "<Cmd>BufferClose<CR>", { silent = true, desc = "Close buffer" })
        map("n", "<Leader>bP", "<Cmd>BufferPick<CR>", { silent = true, desc = "Pick buffer" })
        map(
            "n",
            "<Leader>bo",
            "<Cmd>BufferCloseAllButCurrentOrPinned<CR>",
            { silent = true, desc = "Close other buffers" }
        )
    end,
}
