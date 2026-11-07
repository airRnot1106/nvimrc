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

-- dpp.vim setup
local dpp_base = vim.fn.expand "~/.cache/dpp"
local dpp_repos = dpp_base .. "/repos/github.com"

for _, path in ipairs {
    dpp_repos .. "/vim-denops/denops.vim",
    dpp_repos .. "/Shougo/dpp.vim",
    dpp_repos .. "/Shougo/dpp-ext-installer",
    dpp_repos .. "/Shougo/dpp-ext-lazy",
    dpp_repos .. "/Shougo/dpp-protocol-git",
} do
    vim.opt.runtimepath:prepend(path)
end

local cache = require("dpp-cache").new(dpp_base, vim.fn.stdpath "config" .. "/dpp.ts")

local sourced = false
local function source_once()
    if sourced then
        return
    end
    cache.load()
    sourced = true
end

-- when the reconstruction of state.vim and startup.vim for dpp.vim is complete
vim.api.nvim_create_autocmd("User", {
    pattern = "Dpp:makeStatePost",
    callback = function()
        -- load startup.vim if it has not been loaded yet in this session
        source_once()
        -- start installation for any plugins that have not been cloned yet
        if not cache.install_missing() then
            vim.notify "dpp: Setup complete. Please restart Neovim."
        end
    end,
})

-- regenerate state.vim and startup.vim whenever a plugin clone or update is completed
vim.api.nvim_create_autocmd("User", {
    pattern = "Dpp:ext:installer:updateDone",
    callback = cache.rebuild,
})

-- if the plugin pointed to by state.vim is broken, delete state.vim and startup.vim
if cache.is_broken() then
    cache.discard()
end

-- detect plugins that are not yet installed and install them if any are found
local fresh = cache.load()
sourced = not fresh
if fresh or cache.config_changed() then
    cache.rebuild()
else
    cache.install_missing()
end

vim.cmd "filetype indent plugin on"
vim.cmd "syntax on"

require "config"
