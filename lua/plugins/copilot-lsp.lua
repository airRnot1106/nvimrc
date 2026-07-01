return {
    name = "copilot-lsp",
    repo = "copilotlsp-nvim/copilot-lsp",
    lazy = true,
    lua_add = function()
        vim.g.copilot_nes_debounce = 500
    end,
}
