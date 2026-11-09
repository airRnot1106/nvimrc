return {
    name = "tree-sitter-manager",
    "romus204/tree-sitter-manager.nvim",
    event = { "VimEnter" },
    config = function()
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
