local util = require "lspconfig.util"

local stylelint_config_files = {
    ".stylelintrc",
    ".stylelintrc.mjs",
    ".stylelintrc.cjs",
    ".stylelintrc.js",
    ".stylelintrc.ts",
    ".stylelintrc.json",
    ".stylelintrc.yaml",
    ".stylelintrc.yml",
    "stylelint.config.mjs",
    "stylelint.config.cjs",
    "stylelint.config.js",
    "stylelint.config.ts",
}

---@type vim.lsp.Config
return {
    root_dir = function(bufnr, on_dir)
        local root_markers = { "package-lock.json", "yarn.lock", "pnpm-lock.yaml", "bun.lockb", "bun.lock" }
        root_markers = vim.fn.has "nvim-0.11.3" == 1 and { root_markers, { ".git" } }
            or vim.list_extend(root_markers, { ".git" })

        if vim.fs.root(bufnr, { "deno.json", "deno.jsonc", "deno.lock" }) then
            return
        end

        local project_root = vim.fs.root(bufnr, root_markers) or vim.fn.getcwd()

        local filename = vim.api.nvim_buf_get_name(bufnr)
        local stylelint_config_files_with_package_json =
            util.insert_package_json(stylelint_config_files, "stylelintConfig", filename)
        local is_buffer_using_stylelint = vim.fs.find(stylelint_config_files_with_package_json, {
            path = filename,
            type = "file",
            limit = 1,
            upward = true,
            stop = vim.fs.dirname(project_root),
        })[1]
        if not is_buffer_using_stylelint then
            return
        end

        on_dir(project_root)
    end,
    on_attach = function(client, bufnr)
        vim.api.nvim_buf_create_user_command(bufnr, "LspStylelintFixAll", function()
            client:request_sync("workspace/executeCommand", {
                command = "stylelint.applyAutoFix",
                arguments = {
                    {
                        uri = vim.uri_from_bufnr(bufnr),
                        version = vim.lsp.util.buf_versions[bufnr],
                    },
                },
            }, nil, bufnr)
        end, {})

        vim.api.nvim_create_autocmd("BufWritePre", {
            buffer = bufnr,
            callback = function()
                vim.cmd "LspStylelintFixAll"
            end,
        })
    end,
}
