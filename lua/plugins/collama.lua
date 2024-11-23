return {
    {
        "yuys13/collama.nvim",
        event = { "InsertEnter" },
        config = function()
            require("collama.preset.example").setup { model = "codellama:7b-code" }
            -- map accept key
            vim.keymap.set("i", "<C-h>", require("collama.copilot").accept)

            -- logger
            -- require("collama.logger").setup(require("notify").notify)
        end,
    },
}
