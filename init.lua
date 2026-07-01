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
local denops_src = dpp_repos .. "/vim-denops/denops.vim"
local dpp_config_path = vim.fn.stdpath "config" .. "/dpp.ts"

for _, path in ipairs {
    dpp_repos .. "/Shougo/dpp.vim",
    dpp_repos .. "/Shougo/dpp-ext-installer",
    dpp_repos .. "/Shougo/dpp-ext-lazy",
    dpp_repos .. "/Shougo/dpp-protocol-git",
} do
    vim.opt.runtimepath:prepend(path)
end

local dpp = require "dpp"

local ok, load_failed = pcall(dpp.load_state, dpp_base)
if not ok then
    vim.notify("dpp: failed to load cached state, rebuilding: " .. tostring(load_failed), vim.log.levels.WARN)
    load_failed = true
end

-- Only reload state post-rebuild if nothing was sourced yet this session (avoids E227 double-source)
local state_loaded = not load_failed

local needs_rebuild = load_failed
if state_loaded then
    local stale = dpp.check_files(dpp_base)
    needs_rebuild = type(stale) == "table" and #stale > 0
end

if needs_rebuild then
    vim.opt.runtimepath:prepend(denops_src)

    local reloaded = false
    local function rebuild()
        dpp.make_state(dpp_base, dpp_config_path)
    end

    -- wait_async fires immediately if denops is already ready, unlike a plain DenopsReady autocmd
    vim.fn["denops#server#wait_async"](rebuild)

    vim.api.nvim_create_autocmd("User", {
        pattern = "Dpp:makeStatePost",
        once = true,
        callback = function()
            if not state_loaded and not reloaded then
                reloaded = true
                dpp.load_state(dpp_base)
            end
            local not_installed = vim.fn["dpp#sync_ext_action"]("installer", "getNotInstalled", vim.empty_dict())
            if type(not_installed) == "table" and #not_installed > 0 then
                vim.fn["dpp#async_ext_action"]("installer", "install")
            end
        end,
    })
end

vim.cmd "filetype indent plugin on"
vim.cmd "syntax on"
