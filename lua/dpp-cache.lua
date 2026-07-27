local M = {}

--- Wrap a dpp cache directory (state.vim/startup.vim) and its config file
--- with the lifecycle operations init.lua needs to drive: detect a broken
--- cache, load it, check whether it's stale, rebuild it, and install any
--- plugin that hasn't been cloned yet.
---@param base string dpp base path (e.g. "~/.cache/dpp")
---@param config string path to the dpp config file (dpp.ts)
function M.new(base, config)
    local dpp = require "dpp"
    local state_file = base .. "/nvim/state.vim"
    local startup_file = base .. "/nvim/startup.vim"

    local function when_denops_ready(fn)
        vim.fn["denops#server#wait_async"](fn)
    end

    return {
        -- state.vim may reference a plugin path that no longer exists on
        -- disk; sourcing it as-is would error, so detect that up front.
        is_broken = function()
            local ok, lines = pcall(vim.fn.readfile, state_file)
            if not ok or vim.tbl_isempty(lines) then
                return false
            end
            local ok2, data = pcall(vim.fn.json_decode, lines[1])
            if not ok2 or type(data) ~= "table" or type(data[1]) ~= "table" then
                return false
            end
            for _, p in pairs(data[1]) do
                if
                    type(p) == "table"
                    and type(p.path) == "string"
                    and p.path ~= ""
                    and vim.fn.isdirectory(p.path) == 0
                then
                    return true
                end
            end

            -- startup.vim also bakes the &runtimepath snapshot taken at
            -- `dpp#make_state` time into a literal
            -- `let &runtimepath = '...'` assignment. That includes
            -- entries dpp.ts never registers as plugins (Neovim's own
            -- runtime dir, dpp.vim/denops.vim themselves,
            -- ~/.nix-profile/share/nvim/site, ...), any of which can go
            -- stale (e.g. a nixpkgs rebuild recycles the store path
            -- behind a symlink). If one no longer exists, sourcing it
            -- silently clobbers the correct runtimepath Neovim already
            -- set at startup, breaking $VIMRUNTIME-based files.
            -- dpp's own merge dir is excluded: it merges per-plugin
            -- subdirs (after/, ftplugin/, ...) lazily, so a given
            -- subdir legitimately may not exist yet.
            local merged_dir = base .. "/nvim/.dpp"
            local ok3, startup_lines = pcall(vim.fn.readfile, startup_file)
            if ok3 then
                for _, line in ipairs(startup_lines) do
                    local rtp = line:match "^let &runtimepath = '(.*)'$"
                    if rtp then
                        for path in vim.gsplit(rtp, ",", { plain = true }) do
                            local under_merged_dir = path == merged_dir or vim.startswith(path, merged_dir .. "/")
                            if path ~= "" and not under_merged_dir and vim.fn.isdirectory(path) == 0 then
                                return true
                            end
                        end
                        break
                    end
                end
            end

            return false
        end,

        discard = function()
            vim.fn.delete(state_file)
            vim.fn.delete(startup_file)
        end,

        -- Returns true when there was no (usable) cache to load.
        load = function()
            return dpp.load_state(base)
        end,

        config_changed = function()
            return not vim.tbl_isempty(dpp.check_files(base))
        end,

        rebuild = function()
            when_denops_ready(function()
                dpp.make_state(base, config)
            end)
        end,

        -- Starts an install for any plugin that hasn't been cloned yet.
        -- Returns whether one was started.
        install_missing = function()
            local missing = vim.tbl_filter(function(p)
                return vim.fn.isdirectory(p.rtp) == 0
            end, vim.tbl_values(dpp.get()))
            if #missing == 0 then
                return false
            end
            when_denops_ready(function()
                dpp.async_ext_action("installer", "install")
            end)
            return true
        end,
    }
end

return M
