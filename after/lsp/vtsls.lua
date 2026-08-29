local npm_root = vim.trim(vim.fn.system "npm root -g")
local cmk_ts_plugin_location = vim.env.CMK_TS_PLUGIN_LOCATION or npm_root
local cmk_ts_plugin_available = vim.fn.isdirectory(cmk_ts_plugin_location .. "/@css-modules-kit/ts-plugin") == 1

local filetypes = {
    "javascript",
    "javascriptreact",
    "typescript",
    "typescriptreact",
}

local global_plugins = {}

if cmk_ts_plugin_available then
    table.insert(filetypes, "css")
    table.insert(global_plugins, {
        name = "@css-modules-kit/ts-plugin",
        location = cmk_ts_plugin_location,
        languages = { "css" },
        enableForWorkspaceTypeScriptVersions = true,
    })
end

---@type vim.lsp.Config
return {
    on_init = function(client)
        client.server_capabilities.documentFormattingProvider = false
        client.server_capabilities.documentRangeFormattingProvider = false
    end,
    filetypes = filetypes,
    settings = {
        vtsls = {
            autoUseWorkspaceTsdk = true,
            tsserver = {
                globalPlugins = global_plugins,
            },
        },
        typescript = {
            format = {
                enable = false,
            },
            suggest = {
                completeFunctionCalls = true,
            },
        },
        javascript = {
            format = {
                enable = false,
            },
            suggest = {
                completeFunctionCalls = true,
            },
        },
    },
}
