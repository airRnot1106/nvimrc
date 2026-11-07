return {
    name = "denops",
    "vim-denops/denops.vim",
    lazy = false,
    config = function()
        -- denops discovers plugins only once, when its server starts
        vim.api.nvim_create_autocmd("User", {
            pattern = "LazyLoad",
            group = vim.api.nvim_create_augroup("denops_lazy_load", {}),
            callback = function(args)
                if vim.fn["denops#server#status"]() ~= "running" then
                    return
                end
                local plugin = require("lazy.core.config").plugins[args.data]
                for _, script in ipairs(vim.fn.globpath(plugin.dir, "denops/*/main.ts", true, true)) do
                    local name = vim.fn.fnamemodify(script, ":h:t")
                    if vim.fn["denops#plugin#is_loaded"](name) == 0 then
                        vim.fn["denops#plugin#load"](name, script)
                        vim.fn["denops#plugin#wait"](name)
                    end
                end
            end,
        })
    end,
}
