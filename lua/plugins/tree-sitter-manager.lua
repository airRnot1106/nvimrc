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
                "lua",
                "markdown",
                "markdown_inline",
                "nix",
                "pkl",
                "python",
                "regex",
                "ruby",
                "rust",
                "toml",
                "typescript",
                "typst",
                "vim",
                "yaml",
            },
        }
    end,
}
