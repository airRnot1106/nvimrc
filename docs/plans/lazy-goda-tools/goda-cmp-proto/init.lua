vim.g.mapleader = " "
local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
    vim.fn.system {
        "git",
        "clone",
        "--filter=blob:none",
        "--branch=stable",
        "https://github.com/folke/lazy.nvim.git",
        lazypath,
    }
end
vim.opt.rtp:prepend(lazypath)
local root = vim.fn.stdpath "data" .. "/lazy"
vim.g["goda#workspace"] = { root .. "/goda.vim", root .. "/goda-cmp.vim" }
require("lazy").setup {
    spec = {
        { "Shougo/pum.vim", lazy = true },
        { "Shougo/goda.vim", lazy = true },
        {
            "Shougo/goda-cmp.vim",
            dependencies = { "Shougo/goda.vim", "Shougo/pum.vim" },
            event = { "InsertEnter", "CmdlineEnter" },
            build = ":call goda_cmp#build()",
            config = function()
                vim.fn["goda_cmp#enable"]()
            end,
        },
    },
    install = { colorscheme = {} },
    change_detection = { enabled = false },
    rocks = { enabled = false },
    concurrency = 8,
}
vim.lsp.config("lua_ls", { cmd = { "lua-language-server" }, filetypes = { "lua" }, root_markers = { ".git" } })
vim.lsp.enable "lua_ls"
