vim.loader.enable()

vim.g.mapleader = " "
vim.g.maplocalleader = " "

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
vim.opt.runtimepath:prepend(lazypath)

require("lazy").setup {
    spec = { { import = "plugins" } },
    install = { colorscheme = { "rose-pine" } },
    change_detection = { enabled = false },
    rocks = { enabled = false },
    concurrency = 8,
    performance = {
        rtp = {
            disabled_plugins = {
                "dir",
                "gzip",
                "net",
                "netrwPlugin",
                "rplugin",
                "spellfile",
                "tarPlugin",
                "tutor",
                "zip",
            },
        },
    },
}

require "config"
