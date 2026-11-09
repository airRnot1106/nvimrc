vim.loader.enable()

vim.g.loaded_2html_plugin = true

vim.g.loaded_gzip = true
vim.g.loaded_tar = true
vim.g.loaded_tarPlugin = true
vim.g.loaded_zip = true
vim.g.loaded_zipPlugin = true

vim.g.loaded_vimball = true
vim.g.loaded_vimballPlugin = true

vim.g.loaded_netrw = true
vim.g.loaded_netrwPlugin = true
vim.g.loaded_netrwSettings = true
vim.g.loaded_netrwFileHandlers = true

vim.g.loaded_getscript = true
vim.g.loaded_getscriptPlugin = true

vim.g.loaded_spellfile_plugin = true
vim.g.loaded_tutor_mode_plugin = true
vim.g.did_install_default_menus = true
vim.g.did_install_syntax_menu = true
vim.g.skip_loading_mswin = true
vim.g.loaded_rrhelper = true

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
}

vim.cmd "filetype indent plugin on"
vim.cmd "syntax on"

require "config"
