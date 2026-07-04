return {
    name = "tree-sitter-manager",
    repo = "romus204/tree-sitter-manager.nvim",
    on_event = { "VimEnter" },
    lua_source = function()
        require("tree-sitter-manager").setup {
            ensure_installed = {
                "bash",
                "elixir",
                "gleam",
                "go",
                "javascript",
                "json",
                "kdl",
                "nix",
                "pkl",
                "python",
                "regex",
                "ruby",
                "rust",
                "toml",
                "tsx",
                "typescript",
                "typst",
                "yaml",
            },
        }
    end,
}
