return {
    name = "copilot",
    repo = "zbirenbaum/copilot.lua",
    on_cmd = { "Copilot" },
    on_event = { "InsertEnter" },
    lua_source = function()
        require("copilot").setup {
            suggestion = { enabled = false },
            panel = { enabled = false },
        }
    end,
}
